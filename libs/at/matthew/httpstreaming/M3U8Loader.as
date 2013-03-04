package at.matthew.httpstreaming {
	
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	import org.osmf.elements.proxyClasses.LoadFromDocumentLoadTrait;
	import org.osmf.events.MediaError;
	import org.osmf.events.MediaErrorCodes;
	import org.osmf.events.MediaErrorEvent;
	import org.osmf.media.DefaultMediaFactory;
	import org.osmf.media.MediaElement;
	import org.osmf.media.MediaFactory;
	import org.osmf.media.MediaResourceBase;
	import org.osmf.media.URLResource;
	import org.osmf.net.DynamicStreamingItem;
	import org.osmf.net.DynamicStreamingResource;
	import org.osmf.traits.LoadState;
	import org.osmf.traits.LoadTrait;
	import org.osmf.traits.LoaderBase;
	import org.osmf.utils.URL;
	
	public class M3U8Loader extends LoaderBase {
		
		private static const M3U8_EXTENSION:String = "m3u8";
		
		private var factory:MediaFactory;
		private var loadTrait:LoadTrait;
		
		public function M3U8Loader(factory:MediaFactory = null) {
			super();
			if (!factory) {
				this.factory = new DefaultMediaFactory();
			} else {
				this.factory = factory;
			}
		}
		
		override public function canHandleResource(resource:MediaResourceBase):Boolean {
			if (resource is URLResource) {
				if (resource is DynamicStreamingResource) {
					var dynResource:DynamicStreamingResource = DynamicStreamingResource(resource);
					if (dynResource.streamItems.length > 0)
						return false;
				}
				
				var urlResource:URLResource = URLResource(resource);
				var extension:String = new URL(urlResource.url).extension;
				return extension == M3U8_EXTENSION && resource.getMetadataValue(M3U8Metadata.M3U8_METADATA) == null;
			}
			return false;
		}
		
		override protected function executeLoad(loadTrait:LoadTrait):void {
			this.loadTrait = loadTrait;
			
			updateLoadTrait(loadTrait, LoadState.LOADING);
			
			var req:URLRequest = new URLRequest(URLResource(loadTrait.resource).url);
			var manifestLoader:URLLoader = new URLLoader(req);
			manifestLoader.addEventListener(Event.COMPLETE, onComplete);
			manifestLoader.addEventListener(IOErrorEvent.IO_ERROR, onError);
			manifestLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
			
			function removeListeners():void {
				manifestLoader.removeEventListener(Event.COMPLETE, onComplete);
				manifestLoader.removeEventListener(IOErrorEvent.IO_ERROR, onError);
				manifestLoader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
			}
			
			var attempts:uint = 3;
			function onError(event:ErrorEvent):void {
				attempts--;
				if (attempts == 0) {
					removeListeners();
					updateLoadTrait(loadTrait, LoadState.LOAD_ERROR);
					loadTrait.dispatchEvent(new MediaErrorEvent(MediaErrorEvent.MEDIA_ERROR, false, false, new MediaError(0, event.text)));
				} else {
					manifestLoader.load(req);
				}
			}
			
			function onComplete(event:Event):void {
				removeListeners();
				try {
					var resourceData:String = String((event.target as URLLoader).data);
					var lines:Vector.<String> = Vector.<String>(resourceData.split(/\r?\n/));
					var len:uint = lines.length;
					var netResource:MediaResourceBase;
					
					var dsResource:DynamicStreamingResource;
					var dsItem:DynamicStreamingItem;
					var streamItems:Vector.<DynamicStreamingItem>;
					var rx:RegExp;
					var bw:Number, w:int, h:int;
					
					for (var i:uint = 0; i < len; ++i) {
						if (i == 0) {
							if (lines[i] == "#EXTM3U")
								continue;
							else
								throw new Error("not m3u8");
						}
						// single stream
						if (lines[i].indexOf("#EXTINF") == 0) {
							netResource = loadTrait.resource;
							break;
						}
						// mbr stream
						if (lines[i].indexOf("#EXT-X-STREAM-INF") == 0) {
							if (!dsResource) {
								var baseUrl:String = M3U8Utils.getBaseUrl(URLResource(loadTrait.resource).url);
								netResource = new DynamicStreamingResource(baseUrl);
								dsResource = netResource as DynamicStreamingResource;
								streamItems = new Vector.<DynamicStreamingItem>();
							}
							
							// bandwidth
							rx = /BANDWIDTH=(\d+)/;
							if (lines[i].search(rx) > 0) {
								bw = parseFloat(lines[i].match(rx)[1]) * .001;
							}
							// resolution
							rx = /RESOLUTION=(\d+)x(\d+)/;
							w = h = -1;
							if (lines[i].search(rx) > 0) {
								w = parseInt(lines[i].match(rx)[1]);
								h = parseInt(lines[i].match(rx)[2]);
							}
							dsItem = new DynamicStreamingItem(null, bw, w, h);
							
							// stream name (url)
							i++;
							while (i < len) {
								if (lines[i].length > 0) {
									dsItem.streamName = lines[i];
									streamItems.push(dsItem);
									dsResource.streamItems = streamItems;
									break;
								}
								i++;
							}
						}
					}
					netResource.addMetadataValue(M3U8Metadata.M3U8_METADATA, new M3U8Metadata());
					finishManifestLoad(netResource);
				} catch (parseError:Error) {
					updateLoadTrait(loadTrait, LoadState.LOAD_ERROR);
					loadTrait.dispatchEvent(new MediaErrorEvent(MediaErrorEvent.MEDIA_ERROR, false, false, new MediaError(parseError.errorID, parseError.message)));
				}
			}
		}
		
		override protected function executeUnload(loadTrait:LoadTrait):void {
			updateLoadTrait(loadTrait, LoadState.UNINITIALIZED);
		}
		
		private function finishManifestLoad(netResource:MediaResourceBase):void {
			try {
				var loadedElem:MediaElement = factory.createMediaElement(netResource);
				LoadFromDocumentLoadTrait(loadTrait).mediaElement = loadedElem;
				updateLoadTrait(loadTrait, LoadState.READY);
			} catch (error:Error) {
				updateLoadTrait(loadTrait, LoadState.LOAD_ERROR);
				loadTrait.dispatchEvent(new MediaErrorEvent(MediaErrorEvent.MEDIA_ERROR, false, false, new MediaError(MediaErrorCodes.F4M_FILE_INVALID, error.message)));
			}
		}
		
	}
	
}
