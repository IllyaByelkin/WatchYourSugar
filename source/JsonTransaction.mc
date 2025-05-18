/* Copyright (C) 2024 Illya Byelkin

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <https://www.gnu.org/licenses/>. */

using Toybox.Background;
using Toybox.System as Sys;
import Toybox.Lang;
import Toybox.PersistedContent;
import Toybox.Application;

(:background)
class JsonTransaction extends Toybox.System.ServiceDelegate {

	function initialize() {
		Sys.ServiceDelegate.initialize();
	}
	
    function onTemporalEvent() {
        var valuesInScreen = Properties.getValue("valuesInScreen");
    	makeRequest("http://127.0.0.1:17580/sgv.json?brief_mode=Y&count=" + valuesInScreen);
    }


    function onReceive(responseCode as Number, data as Dictionary) as Void {
        if (responseCode == 200) {
            Background.exit(data);
        } else {
            System.println("Response: " + responseCode);
            Background.exit([{}]);
        }
    }

    function makeRequest(url) as Void {

        var params = {};

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {
            "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON},
            
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        var responseCallback = method(:onReceive);
        Communications.makeWebRequest(url, params, options, responseCallback);
    }
    

}