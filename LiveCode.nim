import sdl2
import sdl2/audio
import os, math, times, locks, dynlib

let SampleRate = 44100
const RQBytesPerSample = 4 
const RQBufferSizeInSamples = 1024
const RQBufferSizeInBytes = RQBufferSizeInSamples * RQBytesPerSample

type RenderFuncType = proc (userdata: pointer, stream: ptr uint8, sampleCount: uint16, byteCount: cint) {.stdcall.}
var renderFunc : RenderFuncType = nil
var obtained: AudioSpec # Actual audio parameters SDL returns

when defined(Windows):
        const RenderLibName* = "RenderFunction.dll" 
elif defined(Linux):
        const RenderLibName* = "libRenderFunction.so" 
elif defined(macosx):
        const RenderLibName* = "libRenderFunction.dylib" 

var RenderFunctionHandle = loadLib(RenderLibName)
var symbol = symAddr(RenderFunctionHandle, "render")
renderFunc = cast[RenderFuncType](symbol)


proc AudioCallback(userdata: pointer; stream: ptr uint8, byteCount: cint) {.cdecl.} =
        if renderFunc != nil:
                renderFunc(userdata, stream, obtained.samples, byteCount)
        else:
                for i in 0..int16(obtained.samples) - 1:
                        cast[ptr int16](cast[int](stream) + i * RQBytesPerSample)[] = 0
                        cast[ptr int16](cast[int](stream) + 2 + i * RQBytesPerSample)[] = 0


proc SetupAudio() =
  # Init audio playback
  if init(INIT_AUDIO) != SdlSuccess:
    echo("Couldn't initialize SDL\n")
    return
  var audioSpec: AudioSpec
  audioSpec.freq = 44100
  audioSpec.format = AUDIO_S16 # 16 bit PCM
  audioSpec.channels = 2       # stereo
  audioSpec.samples = 1024
  audioSpec.padding = 0
  audioSpec.callback = AudioCallback
  audioSpec.userdata = nil
  if openAudio(addr(audioSpec), addr(obtained)) != 0:
    echo("Couldn't open audio device. " & $getError() & "\n")
    return

  echo("frequency: ", obtained.freq)
  echo("format: ", obtained.format)
  echo("channels: ", obtained.channels)
  echo("samples: ", obtained.samples)
  echo("padding: ", obtained.padding)
  if obtained.format != AUDIO_S16:
    echo("Couldn't open 16-bit audio channel.")
    return
  # Playback audio for 2 seconds
  pauseAudio(0)

                
SetupAudio()

var lastWriteTime = getFileInfo("RenderFunction.nim").lastWriteTime
while true:
        if lastWriteTime < getFileInfo("RenderFunction.nim").lastWriteTime:
                discard execShellCmd("nim c --app:lib RenderFunction.nim")
                lastWriteTime = getFileInfo("RenderFunction.nim").lastWriteTime
                unloadLib(RenderFunctionHandle)
                RenderFunctionHandle = loadLib(RenderLibName)
                symbol = symAddr(RenderFunctionHandle, "render")
                renderFunc = cast[RenderFuncType](symbol)
        sleep 1000
