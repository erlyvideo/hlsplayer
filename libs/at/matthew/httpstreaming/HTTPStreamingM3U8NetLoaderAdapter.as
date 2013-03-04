package at.matthew.httpstreaming {
	
	import org.osmf.media.MediaResourceBase;
	import org.osmf.net.HTTPStreamingNetLoaderAdapter;
	import org.osmf.net.PlaybackOptimizationManager;
	import org.osmf.net.httpstreaming.HTTPStreamingFactory;
	
	public class HTTPStreamingM3U8NetLoaderAdapter extends HTTPStreamingNetLoaderAdapter {
		
		public function HTTPStreamingM3U8NetLoaderAdapter(playbackOptimizationManager:PlaybackOptimizationManager) {
			super(playbackOptimizationManager);
		}
		
		override public function canHandleResource(resource:MediaResourceBase):Boolean {
			return resource.getMetadataValue(M3U8Metadata.M3U8_METADATA) != null;
		}
		
		override protected function createHTTPStreamingFactory():HTTPStreamingFactory {
			return new HTTPStreamingM3U8Factory();
		}
		
	}
	
}
