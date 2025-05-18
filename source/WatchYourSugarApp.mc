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

import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;
using Toybox.Background;


class WatchYourSugarApp extends Application.AppBase {


    private var dataChanged;
    private var wasTempEvent = false;
    private var sgvData = [] as Array<Dictionary>;

    function getWasTempEvent() as Boolean {
        if (wasTempEvent) {
            wasTempEvent = false;
            return true;
        } else {
            return false;
        }
    }

    function getSgvData() as Array<Dictionary> {
        return sgvData;
    }

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
        var dataTmp = Storage.getValue("sgvData");
        var flag = Storage.getValue("dataChanged");
        if (dataTmp != null) {
            sgvData = dataTmp;
        }
        if (flag != null) {
            dataChanged = flag;
        }
    }

    function onStop(state as Dictionary?) as Void {
    }

    function getInitialView() {
        if(Toybox.System has :ServiceDelegate) {
    		Background.registerForTemporalEvent(new Time.Duration(5 * 60));
    	} else {
    		System.println("****background not available on this device****");
    	}

        return [new WatchYourSugarView()];
    }

    function getServiceDelegate(){
        return [new JsonTransaction()];
    }

    function onBackgroundData(data) {
        sgvData=data;
        if (sgvData.size() != 0) {
            dataChanged = sgvData[0].get("date") as Number;
            Storage.setValue("sgvData", sgvData);
            Storage.setValue("dataChanged", dataChanged);
        }
        wasTempEvent = true;

        WatchUi.requestUpdate();
    }

    function onSettingsChanged() as Void {
        wasTempEvent = true;
        WatchUi.requestUpdate();
    }

}

function getApp() as WatchYourSugarApp {
    return Application.getApp() as WatchYourSugarApp;
}