HLS Flash player
---------------

This is a complete HLS flash player.

It contains two important folders: src and libs/at.

src contains StrobeMediaPlayback flash player by Adobe in sources. These sources are modified a bit to be able to load m3u8 manifests

libs/at contains code origined from https://code.google.com/p/apple-http-osmf/ by Matthew Kaufman
and it was modified by Mihail Latyshov https://github.com/kutu



Mihail has developed a superior version of HLS plugin from scratch: http://osmfhls.kutu.ru/



Source code is distributed under Mozilla Public License 1.1 as original code.


How to build
===========


  export PATH=$PATH:/usr/local/flex_sdk_4/bin
  make

You will see:

  hlsplayer max$ export PATH=$PATH:/usr/local/flex_sdk_4/bin
  hlsplayer max$ make
  mxmlc -output SMPHLS.swf \
		-source-path libs \
		-library-path assets \
		-library-path libs \
		-static-rsls \
		-define CONFIG::LOGGING false \
		-define CONFIG::FLASH_10_1 true \
		src/StrobeMediaPlayback.as
  Loading configuration file /usr/local/flex_sdk_4/frameworks/flex-config.xml
  /Users/max/Sites/hlsplayer/SMPHLS.swf (282726 bytes)


How to use
==========


Take commercial version of http://erlyvideo.org/ (or any other HLS video server), launch it and add following code to your webpage:

  <div id="player">Video should be here</div>
  <script type="text/javascript">
  $(function() {
    var flashvars = {
      src : "http://streamer/stream/index.m3u8",
      autoPlay: true
    };
    var paramObj = {allowScriptAccess : "always", allowFullScreen : "true", allowNetworking : "all"};
    swfobject.embedSWF("http://streamer/flu/StrobeMediaPlayback.swf", "player", 640, 480, "10.3", "/flu/expressInstall.swf",
      flashvars, paramObj, {name: "StrobeMediaPlayback"});
  });
  </script>













