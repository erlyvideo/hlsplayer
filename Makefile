all:
	mxmlc -output SMPHLS.swf \
		-source-path libs \
		-library-path assets \
		-library-path libs \
		-static-rsls \
		-define CONFIG::LOGGING false \
		-define CONFIG::FLASH_10_1 true \
		src/StrobeMediaPlayback.as
