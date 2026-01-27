import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.Graphics;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.geom.Point;
import openfl.geom.Rectangle;

@:access(openfl.display.Graphics)
@:access(openfl.display.DisplayObject)
@:access(openfl.display.DisplayObjectRenderer)
@:access(openfl.display.Stage)
class Utils {
	static public function roundRect(rect:Rectangle) {
		var w = rect.width;
		var h = rect.height;

		rect.left = Math.floor(rect.left);
		rect.right = w == 0 ? rect.left : Math.ceil(rect.right);
		rect.top = Math.floor(rect.top);
		rect.bottom = h == 0 ? rect.top : Math.ceil(rect.bottom);
	}

	static public function roundPoint(point:Point) {
		point.x = Math.round(point.x);
		point.y = Math.round(point.y);
	}

	static public function clear(o:DisplayObject) {
		var g = getGraphics(o);
		if (g != null)
			g.clear();
		__removeChildren(o);
	}

	static public function __removeChildren(o:DisplayObject) {
		if (Std.isOfType(o, DisplayObjectContainer)) {
			var doc:DisplayObjectContainer = cast o;
			doc.removeChildren();
		}
	}

	static public function getDescendents(o:DisplayObject, includeSelf:Bool = false, result:Array<DisplayObject> = null):Array<DisplayObject> {
		if (result == null)
			result = [];

		if (includeSelf)
			result.push(o);

		function walk(ob:DisplayObject) {
			if (!Std.isOfType(ob, DisplayObjectContainer))
				return;
			var doc:DisplayObjectContainer = cast ob;
			for (i in 0...doc.numChildren) {
				var c = doc.getChildAt(i);
				result.push(c);
				walk(c);
			}
		}
		walk(o);

		return result;
	}

	static public inline function __getScale9GridPosition(pos:Float, start:Float, center:Float, total:Float, scale:Float):Float {
		if (scale <= 0)
			return 0;

		var end = total - start - center;
		var scaledTotal = total * scale;
		var scaledCenter = scaledTotal - start - end;

		// center collapsed → compress start+end uniformly
		if (scaledCenter <= 0) {
			var k = scaledTotal / (start + end);
			if (pos <= start)
				return pos * k;
			else if (pos >= start + center)
				return scaledTotal - (total - pos) * k;
			else
				return start * k;
		}

		// start
		if (pos <= start)
			return pos;

		// end
		if (pos >= start + center)
			return start + scaledCenter + (pos - start - center);

		var k = (pos - start) / center;
		if (k < 0)
			k = 0;
		else if (k > 1)
			k = 1;

		// center
		return start + scaledCenter * k;
	}

	static public function getScale9GridRect(ob:DisplayObject):Rectangle {
		var rect = ob.getRect(ob);
		var minX = rect.x;
		var minY = rect.y;
		var scale9 = ob.scale9Grid;
		var scaledMinX = __getScale9GridPosition(minX, scale9.x, scale9.width, rect.width, ob.scaleX);
		var scaledMinY = __getScale9GridPosition(minY, scale9.y, scale9.height, rect.height, ob.scaleY);
		inline function sx(x:Float):Float {
			return minX + (__getScale9GridPosition(x, scale9.x, scale9.width, rect.width, ob.scaleX) - scaledMinX) / ob.scaleX;
		}
		inline function sy(y:Float):Float {
			return minY + (__getScale9GridPosition(y, scale9.y, scale9.height, rect.height, ob.scaleY) - scaledMinY) / ob.scaleY;
		}
		var p = ob.localToGlobal(new Point(sx(scale9.left), sy(scale9.top)));
		var q = ob.localToGlobal(new Point(sx(scale9.right), sy(scale9.bottom)));
		rect = new Rectangle(p.x, p.y, q.x - p.x, q.y - p.y);
		return rect;
	}

	static public inline function __getScale9GridPositionX(ob:DisplayObject, pos:Float, boundsWidth:Float):Float {
		return __getScale9GridPosition(pos, ob.scale9Grid.x, ob.scale9Grid.width, boundsWidth, ob.scaleX);
	}

	inline function __getScale9GridPositionY(ob:DisplayObject, pos:Float, boundsHeight:Float):Float {
		return __getScale9GridPosition(pos, ob.scale9Grid.y, ob.scale9Grid.height, boundsHeight, ob.scaleY);
	}

	static public function isValidScale9(ob:DisplayObject):Bool {
		var worldMatrix = ob.transform.concatenatedMatrix;
		return ob.scale9Grid != null && worldMatrix.a > 0 && worldMatrix.b == 0 && worldMatrix.c == 0 && worldMatrix.d > 0;
	}

	static public function getGraphics(displayObject:DisplayObject):Graphics {
		if (displayObject is Sprite) {
			return cast(displayObject, Sprite).graphics;
		}
		if (displayObject is Shape) {
			return cast(displayObject, Shape).graphics;
		}
		return null;
	}

	static public function hasGraphics(displayObject:DisplayObject):Bool {
		var g = getGraphics(displayObject);
		#if flash
		return g != null && g.readGraphicsData(false).length > 0;
		#else
		return g != null && g.__commands.length > 0;
		#end
	}

	static public function isHardwareCompatible(g:Graphics):Bool {
		#if flash
		return false;
		#else
		// return g.__isHardwareCompatible;
		return Reflect.getProperty(g, "__isHardwareCompatible") == true;
		#end
	}

	static public function getGLGraphicsDrawCalls(ob:DisplayObject):Int {
		var drawCalls = 0;
		#if (!flash && gl_stats)
		for (c in getDescendents(ob, true)) {
			var g = getGraphics(c);
			if (g == null)
				continue;
			if (!Reflect.hasField(g, "__glDrawCalls"))
				return openfl.display._internal.stats.Context3DStats.totalDrawCalls();
			drawCalls += Reflect.field(g, "__glDrawCalls");
		}
		#end
		return drawCalls;
	}
}
