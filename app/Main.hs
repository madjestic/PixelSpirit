module Main where

import Control.Monad (forever)
import Data.IORef (newIORef)
import Foreign.Marshal.Alloc (malloc)
import Foreign.Marshal.Array (withArray)
import Foreign.Ptr (plusPtr, nullPtr, Ptr)
import Foreign.Storable (sizeOf, peek, poke, Storable)
import Graphics.GLUtil (readTexture, texture2DWrap)
import Graphics.Rendering.OpenGL as GL
import Graphics.UI.GLFW as GLFW
import LoadShaders
import System.Exit (exitSuccess)
import Text.Printf

data Descriptor =
     Descriptor VertexArrayObject NumArrayIndices

data GLMatrix a =
     GLMatrix !a !a !a !a
              !a !a !a !a
              !a !a !a !a
              !a !a !a !a
                deriving Eq

instance PrintfArg a => Show (GLMatrix a) where
  show (GLMatrix m11 m12 m13 m14
                 m21 m22 m23 m24
                 m31 m32 m33 m34
                 m41 m42 m43 m44) =
    let matrix = "[ %v %v %v %v ]\n\
                 \[ %v %v %v %v ]\n\
                 \[ %v %v %v %v ]\n\
                 \[ %v %v %v %v ]\n"
    in printf matrix m11 m12 m13 m14
                     m21 m22 m23 m24
                     m31 m32 m33 m34
                     m41 m42 m43 m44

verticies :: [GLfloat]
verticies =
  [ -- | positions    -- | colors      -- | uv
    1.0,  1.0, 0.0,   1.0, 0.0, 0.0,   1.0, 1.0,
    1.0, -1.0, 0.0,   0.0, 1.0, 0.0,   1.0, 0.0,
   -1.0, -1.0, 0.0,   0.0, 0.0, 1.0,   0.0, 0.0,
   -1.0,  1.0, 0.0,   0.0, 0.0, 0.0,   0.0, 1.0
  ]

indices :: [GLuint]
indices =
  [          -- Note that we start from 0!
    0, 1, 3, -- First Triangle
    1, 2, 3  -- Second Triangle
  ]
     
keyPressed :: GLFW.KeyCallback 
keyPressed win GLFW.Key'Escape _ GLFW.KeyState'Pressed _ = shutdown win
keyPressed _   _               _ _                     _ = return ()
                                                                  
shutdown :: GLFW.WindowCloseCallback
shutdown win =
  do
    GLFW.destroyWindow win
    GLFW.terminate
    _ <- exitSuccess
    return ()                                                                  
     
resizeWindow :: GLFW.WindowSizeCallback
resizeWindow _ w h =
  do
    GL.viewport   $= (GL.Position 0 0, GL.Size (fromIntegral w) (fromIntegral h))
    GL.matrixMode $= GL.Projection
    GL.loadIdentity
    GL.ortho2D 0 (realToFrac w) (realToFrac h) 0   

openWindow :: String -> (Int, Int) -> IO GLFW.Window
openWindow title (sizex,sizey) =
  do
    GLFW.init
    GLFW.defaultWindowHints
    GLFW.windowHint (GLFW.WindowHint'ContextVersionMajor 4)
    GLFW.windowHint (GLFW.WindowHint'ContextVersionMinor 5)
    GLFW.windowHint (GLFW.WindowHint'OpenGLProfile GLFW.OpenGLProfile'Core)
    GLFW.windowHint (GLFW.WindowHint'Resizable False)
    Just win <- GLFW.createWindow sizex sizey title Nothing Nothing
    GLFW.makeContextCurrent (Just win)
    GLFW.setWindowSizeCallback win (Just resizeWindow)
    GLFW.setKeyCallback win (Just keyPressed)
    GLFW.setWindowCloseCallback win (Just shutdown)
    return win

closeWindow :: GLFW.Window -> IO ()
closeWindow win =
  do
    GLFW.destroyWindow win
    GLFW.terminate

display :: IO ()
display =
  do
    inWindow <- openWindow "NGL is Not GLoss" (512,512)
    descriptor <- initResources verticies indices
    onDisplay inWindow descriptor
    closeWindow inWindow
                 
onDisplay :: GLFW.Window -> Descriptor -> IO ()
onDisplay win descriptor@(Descriptor triangles numIndices) =
  do
    GL.clearColor $= Color4 0.1 0.1 0.1 1.0
    GL.clear [ColorBuffer]
    bindVertexArrayObject $= Just triangles
    drawElements Triangles numIndices GL.UnsignedInt nullPtr
    GLFW.swapBuffers win
   
    forever $ do
       GLFW.pollEvents
       onDisplay win descriptor                 

-- | Init resources
---------------------------------------------------------------------------
initResources :: [GLfloat] -> [GLuint] -> IO Descriptor
initResources vs idx =
  do
    -- | VAO
    triangles <- genObjectName
    bindVertexArrayObject $= Just triangles

    -- | VBO
    vertexBuffer <- genObjectName
    bindBuffer ArrayBuffer $= Just vertexBuffer
    let numVertices = length verticies
    withArray verticies $ \ptr ->
      do
        let sizev = fromIntegral (numVertices * sizeOf (head verticies))
        bufferData ArrayBuffer $= (sizev, ptr, StaticDraw)

    -- | EBO
    elementBuffer <- genObjectName
    bindBuffer ElementArrayBuffer $= Just elementBuffer
    let numIndices = length indices
    withArray idx $ \ptr ->
      do
        let indicesSize = fromIntegral (numIndices * (length indices))
        bufferData ElementArrayBuffer $= (indicesSize, ptr, StaticDraw)

    -- | Bind the pointer to the vertex attribute data
    let floatSize  = (fromIntegral $ sizeOf (0.0::GLfloat)) :: GLsizei
        stride     = 8 * floatSize

    -- | Positions
    let vPosition  = AttribLocation 0
        posOffset  = 0 * floatSize
    vertexAttribPointer vPosition $=
        (ToFloat, VertexArrayDescriptor 3 Float stride (bufferOffset posOffset))
    vertexAttribArray vPosition   $= Enabled

    -- | Colors
    let vColor  = AttribLocation 1
        clrOffset  = 3 * floatSize
    vertexAttribPointer vColor $=
        (ToFloat, VertexArrayDescriptor 3 Float stride (bufferOffset clrOffset))
    vertexAttribArray vColor   $= Enabled

    -- | UV
    let uvCoords   = AttribLocation 2
        uvOffset   = 6 * floatSize
    vertexAttribPointer uvCoords  $=
        (ToFloat, VertexArrayDescriptor 2 Float stride (bufferOffset uvOffset))
    vertexAttribArray uvCoords    $= Enabled

    -- || Shaders
    program <- loadShaders [
        ShaderInfo VertexShader   (FileSource "Shaders/01.justice.vert"),
        ShaderInfo FragmentShader (FileSource "Shaders/01.justice.frag")]
    currentProgram $= Just program

    -- Set Uniforms
    location0 <- get (uniformLocation program "u_resolution")
    let u_res = Vector2 512 512 :: Vector2 GLfloat
    uniform location0 $= u_res

    -- Set Transform Matrix
    let tr =
          [ 1, 0, 0, 0
          , 0, 1, 0, 0
          , 0, 0, 1, 0
          , 0, 0, 0, 1 ] :: [GLfloat]
          
    transform <- GL.newMatrix ColumnMajor tr :: IO (GLmatrix GLfloat)
    location1 <- get (uniformLocation program "transform")
    uniform location1 $= (transform)
    
    -- || Unload buffers
    bindVertexArrayObject         $= Nothing
    -- bindBuffer ElementArrayBuffer $= Nothing

    return $ Descriptor triangles (fromIntegral numIndices)

makeStateVarFromPtr :: Storable a => Ptr a -> StateVar a
makeStateVarFromPtr p = makeStateVar (peek p) (poke p)    

bufferOffset :: Integral a => a -> Ptr b
bufferOffset = plusPtr nullPtr . fromIntegral

loadTex :: FilePath -> IO TextureObject
loadTex f =
  do
    t <- either error id <$> readTexture f
    textureFilter Texture2D $= ((Linear', Nothing), Linear')
    texture2DWrap $= (Repeated, ClampToEdge)
    return t
---------------------------------------------------------------------------

main :: IO ()
main =
  do
    display
