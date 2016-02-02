all:
	nim c --threads:on LiveCode.nim
	nim c --app:lib RenderFunction.nim

