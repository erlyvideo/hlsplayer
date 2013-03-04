package at.matthew.httpstreaming {
	
	import org.osmf.media.URLResource;
	import org.osmf.net.DynamicStreamingItem;
	import org.osmf.net.DynamicStreamingResource;
	import org.osmf.metadata.MetadataNamespaces;
	
	public class M3U8Utils {
		
		public static function getBaseUrl(url:String):String {
			if (url.lastIndexOf("/") >= 0) {
				url = url.substr(0, url.lastIndexOf("/") + 1);
			} else {
				url = "";
			}
			return url;
		}
		
		public static function createM3U8IndexInfo(resource:URLResource):M3U8IndexInfo {
			var baseUrl:String = "";
			var streamInfos:Vector.<M3U8StreamInfo> = new Vector.<M3U8StreamInfo>();
			
			if (resource is DynamicStreamingResource) {
				var dsResource:DynamicStreamingResource = resource as DynamicStreamingResource;
				var streamInfo:M3U8StreamInfo;
				var metadata:Object;
				for each (var dynItem:DynamicStreamingItem in dsResource.streamItems) {
					metadata = new Object();
					if (dynItem.width > 0) metadata.width = dynItem.width;
					if (dynItem.height > 0) metadata.height = dynItem.height;
					streamInfo = new M3U8StreamInfo(dynItem.streamName, dynItem.bitrate, metadata);
					streamInfos.push(streamInfo);
				}
				baseUrl = dsResource.host;
			} else {
				streamInfos.push(new M3U8StreamInfo(resource.url, 0, {}));
			}
			
			return new M3U8IndexInfo(baseUrl, streamInfos);
		}
		
	}
	
}
