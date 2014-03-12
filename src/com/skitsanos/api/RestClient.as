/**
 * com.skitsanos.api.RestClient
 * @author Skitsanos (@skitsanos, http://skitsanos.com).
 * @version 1.0
 */
package com.skitsanos.api
{
	import com.adobe.net.URI;

	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;

	import org.httpclient.HttpClient;
	import org.httpclient.HttpRequest;
	import org.httpclient.events.HttpDataEvent;
	import org.httpclient.events.HttpResponseEvent;
	import org.httpclient.events.HttpStatusEvent;
	import org.httpclient.http.Get;

	public class RestClient
	{
		public static var url:String = '';
		public static var useAuthorization:Boolean = false;
		public static var authorizationHeader:URLRequestHeader = null;

		/**
		 * Calls REST API method on server side
		 * @param method API method
		 * @param params null or Object that will be passed to REST API
		 * @param resultHandler Callback function to handle result reply from the API
		 * @param faultHandler Callback function to handle faulty reply from the API
		 */
		public static function execute(method:String, params:*, resultHandler:Function, faultHandler:Function):void
		{
			var actualUrl:String = url;

			if (method != null && method != '')
			{
				actualUrl += method;
			}

			trace('REST API call URL: ' + actualUrl);

			if (params != null)
			{
				var requestPOST:URLRequest = new URLRequest(actualUrl);

				if (useAuthorization && authorizationHeader != null)
				{
					trace(authorizationHeader.value);
					requestPOST.requestHeaders.push(authorizationHeader);
				}

				requestPOST.contentType = "application/json";
				requestPOST.method = "POST";
				requestPOST.data = JSON.stringify(params);

				var loader:URLLoader = new URLLoader();
				loader.dataFormat = URLLoaderDataFormat.TEXT;

				loader.addEventListener(Event.COMPLETE, function (e:Event):void
				{
					var result:Object = JSON.parse(e.target.data);
					resultHandler(result);
				});

				loader.addEventListener(IOErrorEvent.IO_ERROR, function (e:IOErrorEvent):void
				{
					faultHandler({type: 'error', message: e.text});
				});

				loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, function (e:SecurityErrorEvent):void
				{
					faultHandler({type: 'error', message: e.text});
				});

				loader.load(requestPOST);
			}
			else
			{
				var client:HttpClient = new HttpClient();
				var requestGET:HttpRequest = new Get();
				requestGET.contentType = "application/json";

				if (useAuthorization && authorizationHeader != null)
				{
					requestGET.addHeader('Authorization', authorizationHeader.value)
				}

				client.listener.onStatus = function (event:HttpStatusEvent):void
				{
					switch (event.type.toLowerCase())
					{
						case 'error':
							faultHandler({type: 'error', message: event.response.message});
							break;
					}
				};

				client.listener.onComplete = function (event:HttpResponseEvent):void
				{
					// Notified when complete (after status and data)
				};

				client.listener.onData = function (event:HttpDataEvent):void
				{
					trace('GET: ' + event.bytes.readUTFBytes(event.bytes.length));
					event.bytes.position = 0;
					var parsedResult:Object = JSON.parse(event.bytes.readUTFBytes(event.bytes.length));
					if (parsedResult.type == 'error')
					{
						faultHandler(parsedResult);
					}
					else
					{
						resultHandler(parsedResult);
					}
				};

				client.request(new URI(actualUrl), requestGET);
			}
		}
	}
}
