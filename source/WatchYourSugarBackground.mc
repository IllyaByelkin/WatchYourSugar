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
import Toybox.WatchUi;

class Background extends WatchUi.Drawable {

    private var TOP_SCREEN_SGV = 270;

    private var pointsx as Array<Number>;
    private var pointsy as Array<Number>;
    private var isSgvBad as Array<Boolean>;

    private var width as Number?;
    private var height as Number?;

    private var myRed = 0x400000;
    private var myBlue = 0x000040;

    private var maxGoodSgv as Number;
    private var minGoodSgv as Number;
    private var valuesInScreen as Number;

    private var lastValuesInScreen as Number;

    private var valuesGap as Number;

    var app;

    function initialize(params as Dictionary) {

        Drawable.initialize(params);

        app = Application.getApp();

        maxGoodSgv = Properties.getValue("maxGoodSgv");
        minGoodSgv = Properties.getValue("minGoodSgv");
        valuesInScreen = Properties.getValue("valuesInScreen");
        valuesGap = Properties.getValue("valuesGap");

        lastValuesInScreen = valuesInScreen;

        pointsx = new Array<Number>[valuesInScreen];
        pointsy = new Array<Number>[valuesInScreen];
        isSgvBad = new Array<Boolean>[valuesInScreen];
    }

    private function initializeArrayWithValue (array as Array, value) as Array{

        for (var i = 0; i < array.size(); i++) {
            array[i] = value;
        }

        return array;
    }

    /**
     * The function updates the positions of the top points of the
     * sugar plot. This function is called only after the new answer from
     * the localhost is received.
     * 
     * @param dc device context
     * @param sgvData the data from the server with the sugar values
    */
    function updateSgv(dc as Dc, sgvData as Array<Dictionary>) as Void {

        width = dc.getWidth();
        height = dc.getHeight();

        // Update in case settings changed
        maxGoodSgv = Properties.getValue("maxGoodSgv");
        minGoodSgv = Properties.getValue("minGoodSgv");
        valuesInScreen = Properties.getValue("valuesInScreen");
        valuesGap = Properties.getValue("valuesGap");
        var widthStep = Toybox.Math.round(width.toFloat()/(valuesInScreen - 1)); //One segment less then the values

        //Otherwise array out of bounds error after valuesInScreen update
        if (lastValuesInScreen != valuesInScreen) {
            lastValuesInScreen = valuesInScreen;

            pointsx = new Array<Number>[valuesInScreen];
            pointsy = new Array<Number>[valuesInScreen];
            isSgvBad = new Array<Boolean>[valuesInScreen];
        }

        // Initializing with zeros/false for the empty data parts.
        initializeArrayWithValue(pointsx, 0);
        initializeArrayWithValue(pointsy, 0);
        initializeArrayWithValue(isSgvBad, false);

        var numberOfIter = sgvData.size();

        var sugar;
        var time_stamp;
        var real_index;
        var converter;

        // toLong, otherwise integer overflow
        var curr_time = Time.now().value().toLong() * (1000 as Long);

        for (var i = 0; i < numberOfIter; i++) {

            sugar = sgvData[i].get("sgv") as Number;
            time_stamp = sgvData[i].get("date") as Number;

            // Converting timestamp to the array index.
            real_index = (curr_time - time_stamp) / (valuesGap * 60 * 1000);
            real_index = real_index.toNumber();
            real_index = real_index < 0 ? 0 : real_index;

            if (real_index < valuesInScreen) {
            if (sugar > maxGoodSgv || sugar < minGoodSgv) {
                    isSgvBad[real_index] = true;
            } else {
                    isSgvBad[real_index] = false;
            }

                // Converting the array index to the coordinates. Most recent values
                // Should be on the right side (higher coordinate values).
                pointsx[real_index] = width - real_index * widthStep;

                // Some magic of converting sugar values to the screen coordinates
                // sorry I wrote it a long time ago.
            sugar = TOP_SCREEN_SGV - sugar;
            if (sugar < 0) {
                sugar = 0;
            }

            converter = height.toFloat() * (sugar.toFloat() / TOP_SCREEN_SGV);

                pointsy[real_index] =  converter.toNumber();

            } else {
                break;
            }

        }
    }
    function draw(dc as Dc) as Void {
        var numberOfIter = pointsx.size() - 1;

        for (var i = 0; i < numberOfIter; i++) {

            // Part for the data gaps
            if (pointsy[i] == 0 || pointsy[i + 1] == 0) {
                continue;
            }
            if (isSgvBad[i] || isSgvBad[i + 1]) {
                dc.setColor(myRed, myBlue);
                dc.fillPolygon([[pointsx[i + 1], pointsy [i + 1]],[pointsx[i], pointsy[i]],[pointsx[i], height],[pointsx[i + 1], height]]);

                dc.setColor(0xff0000, 0x0000ff);
                dc.drawLine(pointsx[i + 1], pointsy [i + 1],pointsx[i], pointsy[i]);
            } else {
                dc.setColor(myBlue, myRed);
                dc.fillPolygon([[pointsx[i + 1], pointsy [i + 1]],[pointsx[i], pointsy[i]],[pointsx[i], height],[pointsx[i + 1], height]]);

                dc.setColor(0x0000ff, 0xff0000);
                dc.drawLine(pointsx[i + 1], pointsy [i + 1],pointsx[i], pointsy[i]);
            }
        }
    }

}
