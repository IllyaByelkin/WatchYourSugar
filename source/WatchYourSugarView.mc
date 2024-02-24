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
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.PersistedContent;
import Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
import Toybox.WatchUi;
import Toybox.Communications;

class WatchYourSugarView extends WatchUi.WatchFace {

    private var hourView;
    private var minutesView;
    private var dateView;
    private var sugarView;
    private var backgroundView;

    private var app;

    function initialize() {
        WatchFace.initialize();

        app = Application.getApp();
    }

    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));

        hourView = View.findDrawableById("HourLabel") as Text;
        minutesView = View.findDrawableById("MinuteLabel") as Text;
        dateView = View.findDrawableById("DateLabel") as Text;
        sugarView = View.findDrawableById("SugarLabel") as Text;
        backgroundView = View.findDrawableById("BackgroundId") as Background;

        backgroundView.updateSgv(dc, app.getSgvData());
    }

    function onShow() as Void {
    }

    function onUpdate(dc as Dc) as Void {

        var sgvData = app.getSgvData() as Array<Dictionary>;

        var now = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
    
        var hours = now.hour.format("%02d");
        var minutes = now.min.format("%02d");

        var date = now.day.format("%02d");
        var month = now.month;
        var dateString = Lang.format("$1$\n$2$", [month, date]);

        var sugar = "--";

        if (app.getDataChanged()) {

            if (sgvData.size() == 0 || !sgvData[0].hasKey("sgv")){
                return;
            }

            switch(sgvData[0].get("direction")) {
                case "Up":
                    sugar = "^\n";
                    break;
                case "FortyFiveUp":
                    sugar = "/\n";
                    break;
                case "Flat":
                    sugar = "->\n";
                    break;
                case "FortyFiveDown":
                    sugar = "\\\n";
                    break;
                case "Down":
                    sugar = "v\n";
                    break;
                default:
                    sugar = "";
            }

            sugar += (sgvData[0].get("sgv") as Number).format("%d");

            sugarView.setText(sugar);
            backgroundView.updateSgv(dc, sgvData);
        }

        hourView.setText(hours);
        minutesView.setText(minutes);
        dateView.setText(dateString);

        View.onUpdate(dc);
    }

    function onHide() as Void {
        
    }

    function onExitSleep() as Void {
    }

    function onEnterSleep() as Void {
    }

}
