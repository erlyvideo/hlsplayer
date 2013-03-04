/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is the at.matthew.httpstreaming package.
 *
 * The Initial Developer of the Original Code is
 * Matthew Kaufman.
 * Portions created by the Initial Developer are Copyright (C) 2011
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *
 * ***** END LICENSE BLOCK ***** */
 
package at.matthew.httpstreaming {
	
	import flash.net.URLRequest;
	
	import org.osmf.events.HTTPStreamingEvent;
	import org.osmf.events.HTTPStreamingIndexHandlerEvent;
	import org.osmf.net.httpstreaming.HTTPStreamRequest;
	import org.osmf.net.httpstreaming.HTTPStreamRequestKind;
	import org.osmf.net.httpstreaming.HTTPStreamingIndexHandlerBase;
	import org.osmf.net.httpstreaming.flv.FLVTagScriptDataMode;
	import org.osmf.net.httpstreaming.flv.FLVTagScriptDataObject;

	[Event(name="notifyIndexReady", type="org.osmf.events.HTTPStreamingFileIndexHandlerEvent")]
	[Event(name="notifyRates", type="org.osmf.events.HTTPStreamingFileIndexHandlerEvent")]
	[Event(name="notifyTotalDuration", type="org.osmf.events.HTTPStreamingFileIndexHandlerEvent")]
	[Event(name="requestLoadIndex", type="org.osmf.events.HTTPStreamingFileIndexHandlerEvent")]
	[Event(name="notifyError", type="org.osmf.events.HTTPStreamingFileIndexHandlerEvent")]
	[Event(name="DVRStreamInfo", type="org.osmf.events.DVRStreamInfoEvent")]
	
	public class HTTPStreamingM3U8IndexHandler extends HTTPStreamingIndexHandlerBase {
		
		private var _m3u8IndexInfo:M3U8IndexInfo;
		private var _serverBaseURL:String;
		private var _streamInfos:Vector.<M3U8StreamInfo>;
		private var _streamQualityRates:Array;
		private var _streamNames:Array;
		private var _streamUrls:Array;
		
		private var _rateVec:Vector.<HTTPStreamingM3U8IndexRateItem>;
		private var _urlBase:String;
		private var _loadingCount:int;
		private var _numRates:int;
		private var _segment:int;
		private var _absoluteSegment:int;
		private var _indexUpdating:Boolean;
		
		private var _indexString:String;
		
		override public function dispose():void {
			trace("dispose() Error while handle streaming...");
		}
		
		override public function initialize(indexInfo:Object):void {
			_m3u8IndexInfo = indexInfo as M3U8IndexInfo;
			if (!_m3u8IndexInfo || !_m3u8IndexInfo.streamInfos || _m3u8IndexInfo.streamInfos.length <= 0) {
				dispatchEvent(new HTTPStreamingEvent(HTTPStreamingEvent.INDEX_ERROR));
				return;	
			}
			
			_serverBaseURL = _m3u8IndexInfo.baseUrl;
			_streamInfos = _m3u8IndexInfo.streamInfos;
			
			_streamQualityRates = [];
			_streamNames = [];
			_streamUrls = [];
			
			var url:String;
			for each (var item:M3U8StreamInfo in _streamInfos) {
				_streamQualityRates.push(item.bitrate);
				_streamNames.push(item.streamName);
				
				url = item.streamName;
				// if not absolute, then adding baseUrl
				if (url.toLowerCase().search("https?://") != 0) {
					url = _serverBaseURL + url;
				}
				_streamUrls.push(url);
			}
			
			_rateVec = new Vector.<HTTPStreamingM3U8IndexRateItem>(_streamInfos.length, true); // deliberately losing reference to old one, if present
			
			notifyRatesReady();
			dispatchIndexLoadRequest(0);
		}
	
		override public function processIndexData(data:*, indexContext:Object):void {
//			trace("processIndexData", indexContext);
			var quality:int = indexContext as int;
			_indexUpdating = false;
			
			var lines:Vector.<String> = Vector.<String>(String(data).split(/\r?\n/));
			
			var rateItem:HTTPStreamingM3U8IndexRateItem;
			var manifestItem:HTTPStreamingM3U8IndexItem;
			var i:uint;
			var len:uint = lines.length;
			var url:String;
			var duration:Number;
			var sequence:Number;
			
			rateItem = new HTTPStreamingM3U8IndexRateItem(_streamQualityRates[quality], _streamUrls[quality]);
			_rateVec[quality] = rateItem;
			
			for (i = 0; i < len; ++i) {
				if (i == 0) {
					if (lines[i] == "#EXTM3U") {
						continue;
					} else {
						trace("first line wasn't #EXTM3U was instead " + lines[0]);
						dispatchEvent(new HTTPStreamingEvent(HTTPStreamingEvent.INDEX_ERROR));
						return;	
					}
				}
				if (lines[i].indexOf("#EXTINF") == 0) {
					duration = parseFloat(lines[i].match(/(\d+)/)[1]);
					i++;
					while (i < len) {
						if (lines[i].length > 0) {
							if (lines[i].toLowerCase().search("https?://") == 0) {
								url = String(lines[i]);
							} else {
								url = rateItem.urlBase + lines[i];
							}
							manifestItem = new HTTPStreamingM3U8IndexItem(duration, url);
							rateItem.addIndexItem(manifestItem);
							break;
						}
						i++;
					}
				}
				if (lines[i].indexOf("#EXT-X-ENDLIST") == 0) {
					// This is not a live stream
					rateItem.live = false;
				}
				if (lines[i].indexOf("#EXT-X-MEDIA-SEQUENCE") == 0) {
					sequence = parseFloat(lines[i].match(/(\d+)/)[1]);
					rateItem.sequenceNumber = sequence;
				}
			}
			
			var offset:Number = 0;
			if (rateItem.live) {
				offset = rateItem.totalTime - (	( rateItem.totalTime / rateItem.manifest.length ) * 3);
			}
			notifyIndexReady(quality, offset);
		}
		
		override public function getFileForTime(time:Number, quality:int):HTTPStreamRequest {
			// check if rate item exist
			var request:HTTPStreamRequest = checkRateItemExist(quality);
			if (request) return request;
			
			var item:HTTPStreamingM3U8IndexRateItem = _rateVec[quality];
			var manifest:Vector.<HTTPStreamingM3U8IndexItem> = item.manifest;
			var i:int;
			for each (var indexItem:HTTPStreamingM3U8IndexItem in manifest) {
				if (time < indexItem.startTime) break;
				i++;
			}
			if (i > 0) i--;
			
			_segment = i;
			_absoluteSegment = item.sequenceNumber + _segment; // we also need to set the absolute segment in case we are starting at an offset (live)
			
			return getNextFile(quality);
		}

		override public function getNextFile(quality:int):HTTPStreamRequest {
//			trace("getNextFile quality:", quality);
			var request:HTTPStreamRequest;
			
			// check if rate item exist
			request = checkRateItemExist(quality);
			if (request) return request;
			
			var item:HTTPStreamingM3U8IndexRateItem = _rateVec[quality];
			var manifest:Vector.<HTTPStreamingM3U8IndexItem> = item.manifest;
			var i:int;
			
			notifyTotalDuration(item.totalTime, quality, item.live);
			
			if (item.live) {
				// Initialize live playback
				if (_absoluteSegment == 0 && _segment == 0) {
					_absoluteSegment = item.sequenceNumber + _segment;
				}
				// We re-loaded the live manifest, need to re-normalize the list
				if (_absoluteSegment != item.sequenceNumber + _segment) {
					_segment = _absoluteSegment - item.sequenceNumber;
					if (_segment < 0) {
						_segment = 0;
						_absoluteSegment = item.sequenceNumber;
					}
				}
				// Try to force a reload
				if (_segment >= manifest.length) {
					if (!_indexUpdating) {
						_indexUpdating = true;
						dispatchIndexLoadRequest(quality);
					}
					request = new HTTPStreamRequest(HTTPStreamRequestKind.RETRY, null, 1);
				} 
			}
			
			if (_segment >= manifest.length) {
				if (!item.live) {
					// no more segments, we are done
					request = new HTTPStreamRequest(HTTPStreamRequestKind.DONE);
				}
			} else {
				request = new HTTPStreamRequest(HTTPStreamRequestKind.DOWNLOAD, manifest[_segment].url);
				dispatchEvent(new HTTPStreamingEvent(HTTPStreamingEvent.FRAGMENT_DURATION, false, false,
					manifest[_segment].duration, null, null));
				_segment++;
				_absoluteSegment++;
			}
			
//			trace("download:", request.url);
			
			return request;
		}
		
		override public function dvrGetStreamInfo(indexInfo:Object):void {
		}
		
		private function checkRateItemExist(quality:int):HTTPStreamRequest {
			if (!_rateVec[quality]) {
				if (_streamInfos.length > quality) {
					if (!_indexUpdating) {
						dispatchIndexLoadRequest(quality);
					}
					return new HTTPStreamRequest(HTTPStreamRequestKind.RETRY, null, 1);
				} else {
					return new HTTPStreamRequest(HTTPStreamRequestKind.DONE);
				}
			}
			return null;
		}
		
		private function dispatchIndexLoadRequest(quality:int):void {
			_indexUpdating = true;
			dispatchEvent(
				new HTTPStreamingIndexHandlerEvent(
					HTTPStreamingIndexHandlerEvent.REQUEST_LOAD_INDEX
					, false
					, false
					, false
					, NaN
					, null
					, null
					, new URLRequest(_streamUrls[quality])
					, quality
					, true
				)
			);
		}
		
		private function notifyTotalDuration(duration:Number, quality:int, live:Boolean):void {
			var metaInfo:Object = _streamInfos[quality].metadata;
			metaInfo.duration = live ? 0 : duration;

			var sdo:FLVTagScriptDataObject = new FLVTagScriptDataObject();
			sdo.objects = ["onMetaData", metaInfo];
			dispatchEvent(
				new HTTPStreamingEvent(
					HTTPStreamingEvent.SCRIPT_DATA
					, false
					, false
					, 0
					, sdo
					, FLVTagScriptDataMode.IMMEDIATE
					)
				);
		}
		
		private function notifyRatesReady():void {
			dispatchEvent(
				new HTTPStreamingIndexHandlerEvent(
					HTTPStreamingIndexHandlerEvent.RATES_READY
					, false
					, false
					, false
					, NaN
					, _streamNames
					, _streamQualityRates
				)
			);
		}
		
		private function notifyIndexReady(quality:int, offset:Number = 0):void {
			dispatchEvent(
				new HTTPStreamingIndexHandlerEvent(
					HTTPStreamingIndexHandlerEvent.INDEX_READY
					, false
					, false
					, _rateVec[quality].live
					, offset
				)
			);
		}
		
	}
	
}
