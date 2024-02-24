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

    private var pointsx as Array<Number>;
    private var pointsy as Array<Number>;
    private var isSgvBad as Array<Boolean>;

    private var width as Number?;
    private var height as Number?;

    private var myRed = 0x400000;
    private var myBlue = 0x000040;

    function initialize(params as Dictionary) {

        Drawable.initialize(params);

        pointsx = new Array<Number>[12];
        pointsy = new Array<Number>[12];
        isSgvBad = new Array<Boolean>[12];
    }

    function updateSgv(dc as Dc, sgvData as Array<Dictionary>) as Void {
        width = dc.getWidth();
        height = dc.getHeight();
        var widthStep = Toybox.Math.round(width.toFloat()/(12 - 1)); //One segment less then the values

        var numberOfIter = sgvData.size();

        var sugar;
        var converter;


        for (var i = 0; i < numberOfIter; i++) {
            sugar = sgvData[i].get("sgv") as Number;

            if (sugar == null) {
                break;
            }

            if (sugar > 180 || sugar < 80) {
                isSgvBad[i] = true;
            } else {
                isSgvBad[i] = false;
            }

            pointsx[i] = width - i * widthStep;

            sugar = 270 - sugar;
            if (sugar < 0) {
                sugar = 0;
            }

            converter = height.toFloat() * (sugar.toFloat() / 270);

            pointsy[i] =  converter.toNumber();
        }

        pointsx[numberOfIter - 1] = 0; //In case when width is not devideble through (valuesInScreen - 1)
    }

    function draw(dc as Dc) as Void {
        if (pointsx[0] == null || pointsx[1] == null) {
            return;
        }
        var numberOfIter = pointsx.size() - 1;

        for (var i = 0; i < numberOfIter; i++) {
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
