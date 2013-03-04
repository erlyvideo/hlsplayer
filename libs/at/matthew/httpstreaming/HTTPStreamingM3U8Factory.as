package at.matthew.httpstreaming {
	
	import org.osmf.media.MediaResourceBase;
	import org.osmf.media.URLResource;
	import org.osmf.net.httpstreaming.HTTPStreamingFactory;
	import org.osmf.net.httpstreaming.HTTPStreamingFileHandlerBase;
	import org.osmf.net.httpstreaming.HTTPStreamingIndexHandlerBase;
	import org.osmf.net.httpstreaming.HTTPStreamingIndexInfoBase;
	
	public class HTTPStreamingM3U8Factory extends HTTPStreamingFactory {
		
		override public function createFileHandler(resource:MediaResourceBase):HTTPStreamingFileHandlerBase {
			return new HTTPStreamingMP2TSFileHandler();
		}
		
		override public function createIndexHandler(resource:MediaResourceBase, fileHandler:HTTPStreamingFileHandlerBase):HTTPStreamingIndexHandlerBase {
			return new HTTPStreamingM3U8IndexHandler();
		}
		
		override public function createIndexInfo(resource:MediaResourceBase):HTTPStreamingIndexInfoBase {
			return M3U8Utils.createM3U8IndexInfo(resource as URLResource);
		}
		
	}
	
}
