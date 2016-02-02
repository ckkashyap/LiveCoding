import math
{.pragma: rtl, exportc, dynlib}

const RQBytesPerSample = 4  # 16 bit PCM

let M = 1.0595
var Frequence = 880     # Hz
let Volume = 0.05         # [0..1]

let SampleRate = 44100    # Hz

var ctr = 0

var x = 0
var xx = 0

## Generate a sine wave
var c = float(SampleRate) / float(Frequence)
proc render*(userdata: pointer, stream: ptr uint8, sampleCount: uint16, byteCount: cint) {.cdecl exportc.} =
                for i in 0..int16(sampleCount) - 1:
                        var y = int16(round(sin(float(x mod int(c)) / c * 2 * PI) * 32767 * Volume))
                        inc(x)
                        if xx < 20000:
                            cast[ptr int16](cast[int](stream) + i * RQBytesPerSample)[] = y
                            cast[ptr int16](cast[int](stream) + 2 +  i * RQBytesPerSample)[] = 0
                        else:
                            cast[ptr int16](cast[int](stream) + i * RQBytesPerSample)[] = 0
                            cast[ptr int16](cast[int](stream) + 2 +  i * RQBytesPerSample)[] = y
                        inc (xx)
                        if xx == 40000: xx = 0

