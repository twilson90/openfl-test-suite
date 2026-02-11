import openfl.display.Sprite;
import openfl.events.Event;
import openfl.Lib;

class FrameTimingTest extends Sprite {
	public function new() {
		super();

		var i = 0;
		var steps = 120;
		var spr = new Sprite();
		var g = spr.graphics;
		addChild(spr);

		function onEnterFrame(e:Event) {
			i++;
			var r = (i / steps) * 360;
			spr.rotation = r;
			var d = i % 2;
			g.clear();
			if (d == 0)
				g.beginFill(0xff0000);
			else
				g.beginFill(0x00ff00);

			var cx = Lib.current.stage.stageWidth / 2;
			var cy = Lib.current.stage.stageHeight / 2;
			spr.x = cx;
			spr.y = cy;
			g.drawRect(-300, -300, 600, 600);
		};
		addEventListener(Event.ENTER_FRAME, onEnterFrame);
	}
}
