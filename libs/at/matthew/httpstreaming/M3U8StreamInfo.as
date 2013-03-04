package at.matthew.httpstreaming {
	
	public class M3U8StreamInfo {
		
		private var _streamName:String;
		private var _bitrate:Number;
		private var _metadata:Object;
		
		public function M3U8StreamInfo(streamName:String, bitrate:Number, metadata:Object) {
			_streamName = streamName;
			_bitrate = bitrate;
			_metadata = metadata;
		}
		
		public function get streamName():String { return _streamName }
		public function get bitrate():Number { return _bitrate }
		public function get metadata():Object { return _metadata }
		
	}
	
}
