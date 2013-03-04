package at.matthew.httpstreaming {
	
	import org.osmf.elements.LoadFromDocumentElement;
	import org.osmf.media.MediaResourceBase;
	import org.osmf.traits.LoaderBase;
	
	public class M3U8Element extends LoadFromDocumentElement {
		
		public function M3U8Element(resource:MediaResourceBase=null, loader:LoaderBase=null) {
			if (loader == null) {
				loader = new M3U8Loader();
			}
			super(resource, loader);
		}
		
	}
	
}
