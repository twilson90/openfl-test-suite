package;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import openfl.events.Event;
import openfl.geom.Rectangle;
import openfl.Lib;

class FrameTimeGraph extends Sprite {
	public function new(widthPx:Int = 200, heightPx:Int = 60) {
		super();

		var bg = 0xA00F0F0F;
		var bmpData = new BitmapData(widthPx, heightPx, true, bg);
		var bmp = new Bitmap(bmpData);
		addChild(bmp);

		var lastTime = Lib.getTimer();

		var stage = Lib.current.stage;
		var avg = new RollingAverage(60);

		var tf = new TextField();
		var tff = new TextFormat("Arial", 10, 0xFFFFFF);
		tf.defaultTextFormat = tff;
		tf.text = "Frame Time";
		tf.autoSize = TextFieldAutoSize.LEFT;
		addChild(tf);

		function onFrame(_) {
			var now = Lib.getTimer();
			var delta = now - lastTime;
			lastTime = now;
			var targetMs = Math.round(1000.0 / stage.frameRate);
			var maxMs = targetMs * 2.0;
			avg.add(delta);
			var avgMs = avg.getAverage();

			// scroll left
			bmpData.scroll(-1, 0);
			bmpData.fillRect(new Rectangle(widthPx - 1, 0, 1, heightPx), bg);

			// scale
			var clamped = Math.min(delta, maxMs);
			var barHeight = Std.int((clamped / maxMs) * heightPx);

			var color:Int;
			if (delta > targetMs)
				color = 0xCCFFCC33;
			else
				color = 0xCC33FF66;

			// draw bar (bottom-up)
			var baseY = heightPx - Std.int((clamped / maxMs) * heightPx);
			bmpData.fillRect(new Rectangle(widthPx - 1, baseY, 1, barHeight), color);
			tf.text = Std.int(delta) + "ms | avg: " + Std.int(avgMs) + "ms";

			// draw baseline
			var baseY = heightPx - Std.int((targetMs / maxMs) * heightPx);
			bmpData.setPixel(widthPx - 1, baseY, 0xCC444444);
		}
		addEventListener(Event.ENTER_FRAME, onFrame);
	}
}

class RollingAverage {
	public var size(default, null):Int;

	var values:Array<Float>;
	var sum:Float = 0.0;
	var index:Int = 0;
	var count:Int = 0;

	public function new(size:Int) {
		this.size = size;
		values = [];
		values.resize(size);
		for (i in 0...size)
			values[i] = 0.0;
	}

	/** Add a new sample */
	public function add(v:Float):Void {
		// Remove the value that's about to be overwritten
		sum -= values[index];

		// Store new value
		values[index] = v;
		sum += v;

		index = (index + 1) % size;

		if (count < size)
			count++;
	}

	/** Current rolling average */
	public inline function getAverage():Float {
		return count == 0 ? 0.0 : sum / count;
	}

	/** Optional: how full the buffer is (0–1) */
	public inline function getFillRatio():Float {
		return count / size;
	}

	/** Reset everything */
	public function clear():Void {
		for (i in 0...size)
			values[i] = 0.0;
		sum = 0.0;
		index = 0;
		count = 0;
	}
}
