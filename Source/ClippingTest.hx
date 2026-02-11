import openfl.display.Sprite;
import openfl.Lib;

class ClippingTest extends Sprite {
	public function new() {
		super();

		var thickness = 100;
		var r = 150;
		var x = 200;
		var y = 300;
		graphics.lineStyle(thickness, 0, 0.5, false, NORMAL, null, MITER);
		graphics.beginFill(0xff0000);
		graphics.drawRect(x, y, r, r);
		graphics.endFill();

		scaleX = 2.7925;
		scaleY = 0.3575;
	}
}
