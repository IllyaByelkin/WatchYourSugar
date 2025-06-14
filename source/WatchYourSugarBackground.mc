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
        initializeArrayWithValue(pointsx, -1);
        initializeArrayWithValue(pointsy, -1);
        initializeArrayWithValue(isSgvBad, false);

        var numberOfIter = sgvData.size();

        var sugar;
        var time_stamp;
        var real_index;
        var converter;

        // toLong, otherwise integer overflow
        var curr_time = Time.now().value().toLong() * (1000 as Long);

        var prev_index = -1;

        for (var i = 0; i < numberOfIter; i++) {

            sugar = sgvData[i].get("sgv") as Number;
            time_stamp = sgvData[i].get("date") as Number;

            if (time_stamp == null) {
                return;
            }

            // Converting timestamp to the array index.
            real_index = (curr_time - time_stamp).toDouble() / (valuesGap * 60 * 1000);
            real_index = Toybox.Math.round(real_index);
            real_index = real_index.toNumber();
            real_index = real_index < 0 ? 0 : real_index;

            if (real_index == prev_index) {
                real_index++;
            }

            if (real_index < valuesInScreen) {
                if (sugar > maxGoodSgv || sugar < minGoodSgv) {
                    isSgvBad[real_index] = true;
                } else {
                    isSgvBad[real_index] = false;
                }

                // Converting the array index to the coordinates. Most recent values
                // Should be on the right side (higher coordinate values).
                pointsx[real_index] = width - real_index * widthStep;

                // maximal sugar value visible in the screen minus actual, because
                // coordinates begin on the top left corner
                sugar = TOP_SCREEN_SGV - sugar;
                if (sugar < 0) {
                    sugar = 0;
                }

                //normalize to the screen size
                converter = height.toFloat() * (sugar.toFloat() / TOP_SCREEN_SGV);

                pointsy[real_index] =  converter.toNumber();

            } else {
                break;
            }

        }
    }

    function makeColorDarker(color as Number, factor as Float) as Number{

        if (factor < 0 || factor > 1) {
            return color;
        }

        var r = (color >> 16) & 0xFF;
        var g = (color >> 8) & 0xFF;
        var b = color & 0xFF;

        r *= factor;
        g *= factor;
        b *= factor;

        r = r.toNumber();
        g = g.toNumber();
        b = b.toNumber();

        return ((r << 16) | (g << 8) | b);
    }

    /**
     * The plot consist of basically two elements:
     * - rectangular with a darker color
     * - line with a brighter color
     * both elements could be of two color, for the good and bad sugar.
     * Line is placed just over the top line of the rectangular for the
     * aesthetic purposes.
     * Positions of the figures updated by the updateSgv function.
     * 
     * @param dc device context
    */
    function draw(dc as Dc) as Void {
        var numberOfIter = pointsx.size() - 1;

        var colorGood = Properties.getValue("colorGood");
        var colorBad = Properties.getValue("colorBad");
        var darkColorGood = makeColorDarker(colorGood, 0.25);
        var darkColorBad = makeColorDarker(colorBad, 0.25);

        for (var i = 0; i < numberOfIter; i++) {

            // Part for the data gaps
            if (pointsy[i] < 0 || pointsy[i + 1] < 0) {
                continue;
            }
            if (isSgvBad[i] || isSgvBad[i + 1]) {
                dc.setColor(darkColorBad, darkColorGood);
                dc.fillPolygon([[pointsx[i + 1], pointsy [i + 1]],[pointsx[i], pointsy[i]],[pointsx[i], height],[pointsx[i + 1], height]]);

                dc.setColor(colorBad, colorGood);
                dc.drawLine(pointsx[i + 1], pointsy [i + 1],pointsx[i], pointsy[i]);
            } else {
                dc.setColor(darkColorGood, darkColorBad);
                dc.fillPolygon([[pointsx[i + 1], pointsy [i + 1]],[pointsx[i], pointsy[i]],[pointsx[i], height],[pointsx[i + 1], height]]);

                dc.setColor(colorGood, colorBad);
                dc.drawLine(pointsx[i + 1], pointsy [i + 1],pointsx[i], pointsy[i]);
            }
        }
    }

}
