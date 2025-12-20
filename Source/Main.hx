package;

import openfl.text.TextFormat;
import openfl.text.TextField;
import openfl.display.DisplayObjectContainer;
import openfl.Lib;
import openfl.Vector;
import openfl.display.DisplayObject;
import openfl.display.Bitmap;
import openfl.display.FPS;
import openfl.display.GradientType;
import openfl.display.InterpolationMethod;
import openfl.display.SpreadMethod;
import openfl.display.Sprite;
import openfl.display.Shape;
import openfl.display.CapsStyle;
import openfl.display.JointStyle;
import openfl.display.LineScaleMode;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.ui.Keyboard;
import openfl.utils.Assets;
import openfl.text.TextFieldAutoSize;
import format.SVG;


@:access(openfl.display.Graphics)
class Main extends Sprite {
	public var currentIndex = 0;
	public var pause = false;
	public var showBounds:Bool = false;
	public var showColorTransform:Bool = false;
	public var showMask:Bool = false;
	public var showOpaqueBackgrounds:Bool = false;
	public var current:TestContainer;
	public var tests:Array<Dynamic> = [
		Scale9Test,
		GraphicsTest1,
		FillLineStyleOrderTest,
		SVGTest,
		GradientTest,
		CloseGapTest,
		SpinningTest,
		MiterBoundsTest,
		Scale9Test2,
	];

	public var boundsSprite = new Sprite();
	public var hitTestSprite = new Sprite();

	public var testColors:Array<Int> = [
		0xFF0000, // Red
		0x00FF00, // Green
		0x0000FF, // Blue
		0xFFFF00, // Yellow
		0xFF00FF, // Magenta
		0x00FFFF, // Cyan
		0xFF8800, // Orange
		0x88FF00, // Lime
		0x0088FF, // Sky Blue
		0xFF0088, // Hot Pink
		0x8800FF, // Purple
		0x00FF88  // Mint
	];

	public var maskSprite = new Sprite();

	public var emptyColorTransform = new ColorTransform();
	public var colorTransform = new ColorTransform(0.5,0.5,0.5, 1.0);
	
	public function new() {
		super();

		addChild(boundsSprite);
		addChild(hitTestSprite);
		
		maskSprite.graphics.beginFill(0, 1);
		maskSprite.graphics.drawEllipse(-200,-100,400,200);
		addChild(maskSprite);

		var funcMap = [
			{ name: "Previous Test", key: Keyboard.LEFT, keyName: "Left Arrow", func: previousTest },
			{ name: "Next Test", key: Keyboard.RIGHT, keyName: "Right Arrow", func: nextTest },
			{ name: "Toggle OpaqueBackground", key: Keyboard.NUMBER_1, keyName: "1", func: toggleOpaqueBackgrounds },
			{ name: "Toggle Bounds", key: Keyboard.NUMBER_2, keyName: "2", func: toggleBounds },
			{ name: "Toggle ColorTransform", key: Keyboard.NUMBER_3, keyName: "3", func: toggleColorTransform },
			{ name: "Toggle Mask", key: Keyboard.NUMBER_4, keyName: "4", func: toggleMask },
			{ name: "Pause Animations", key: Keyboard.SPACE, keyName: "Space", func: togglePause },
			{ name: "Clear HitTest Markers", key: Keyboard.DELETE, keyName: "Delete", func: clearHitTestSprite },
		];

		Lib.current.stage.addEventListener(KeyboardEvent.KEY_UP, function(e:KeyboardEvent) {
			for (o in funcMap) {
				if (e.keyCode == cast o.key) {
					o.func();
				}
			}
		});

		var instructions = new TextField();
		formatTextField(instructions);
		addChild(instructions);

		var currentTestTextField = new TextField();
		formatTextField(currentTestTextField);
		addChild(currentTestTextField);

		var infoTF = new TextField();
		formatTextField(infoTF);
		addChild(infoTF);
		
		Lib.current.stage.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent) {
			current.onMouseDown(e);
		});
		Lib.current.stage.addEventListener(MouseEvent.MOUSE_MOVE, function(e:MouseEvent) {
			current.onMouseMove(e);
		});
		Lib.current.stage.addEventListener(MouseEvent.MOUSE_UP, function(e:MouseEvent) {
			current.onMouseUp(e);
		});
		Lib.current.stage.addEventListener(KeyboardEvent.KEY_UP, function(e:KeyboardEvent) {
			current.onKeyDown(e);
		});
		Lib.current.stage.addEventListener(KeyboardEvent.KEY_DOWN, function(e:KeyboardEvent) {
			current.onKeyUp(e);
		});

		var i = 0;
		var hitTest = false;
		addEventListener(Event.ENTER_FRAME, function(e:Event) {

			if (!pause) {
				current.onEnterFrame(e);
				maskSprite.x = Lib.current.stage.mouseX;
				maskSprite.y = Lib.current.stage.mouseY;
				maskSprite.scaleX = maskSprite.scaleY = Math.sin(i * Math.PI / 180);
				maskSprite.rotation = i * 2;
				i++;
			}

			if (current.center) {
				var bounds = current.getBounds(current);
				current.x = Math.round((Lib.current.stage.stageWidth - bounds.width)/2.0 - bounds.x);
				current.y = Math.round((Lib.current.stage.stageHeight - bounds.height)/2.0 - bounds.y);
			} else {
				current.x = current.y = 0;
			}

			var newHitTest = current.hitTestPoint(stage.mouseX, stage.mouseY, true);

			if (newHitTest && !hitTest) {
				hitTestSprite.graphics.drawRect(stage.mouseX-2, stage.mouseY-2, 4, 4);
			}

			hitTest = newHitTest; 

			infoTF.text = "HIT: " + (newHitTest ? "YES" : "NO");
			infoTF.y = Lib.current.stage.stageHeight - infoTF.height;

			current.mask = showMask ? maskSprite : null;
			maskSprite.visible = showMask;
			
			current.transform.colorTransform = showColorTransform ? colorTransform : emptyColorTransform;

			boundsSprite.graphics.clear();
			if (showBounds) {
				drawBounds(current);
			}
			showOpaqueBackground(current, showOpaqueBackgrounds);

			var str = Type.getClassName(tests[currentIndex]);
			if (current.info != null) {
				str += ": " + current.info;
			}
			currentTestTextField.text = str;
			
			instructions.text = funcMap.map((f)->{
				return f.keyName + " → " + f.name;
			}).join("\n");
			instructions.x = Lib.current.stage.stageWidth - instructions.width;
			instructions.y = 0;
		});
		
		loadTest();
	}

	public function loadTest() {
		if (current != null) {
			current.destroy();
		}
		clearHitTestSprite();
		var test_clazz = tests[currentIndex];
		current = cast Type.createInstance(test_clazz, []);
		addChildAt(current, 0);
		current.name = Type.getClassName(test_clazz);
		current.init();
	}

	function formatTextField(textfield:TextField) {
		textfield.border = true;
		textfield.borderColor = 0x000000;
		textfield.background = true;
		textfield.backgroundColor = 0xeeeeee;
		textfield.textColor = 0x000000;
		textfield.defaultTextFormat = new TextFormat("Arial", 12);
		textfield.autoSize = TextFieldAutoSize.LEFT;
	}

	function showOpaqueBackground(displayObject:DisplayObject, show:Bool, i:Int = 0) {
		var color = testColors[i++ % testColors.length];
		displayObject.opaqueBackground = show ? color : null;
		if (Std.isOfType(displayObject, DisplayObjectContainer)) {
			var container:DisplayObjectContainer = cast displayObject;
			for (c in 0...container.numChildren) {
				showOpaqueBackground(container.getChildAt(c), show, i++);
			}
		}
	}

	function previousTest() {
		currentIndex = (currentIndex - 1 + tests.length) % tests.length;
		loadTest();
	}

	function nextTest() {
		currentIndex = (currentIndex + 1) % tests.length;
		loadTest();
	}

	function toggleOpaqueBackgrounds() {
		showOpaqueBackgrounds = !showOpaqueBackgrounds;
	}

	function toggleBounds() {
		showBounds = !showBounds;
	}

	function toggleColorTransform() {
		showColorTransform = !showColorTransform;
	}

	function toggleMask() {
		showMask = !showMask;
	}

	function togglePause() {
		pause = !pause;
	}

	function clearHitTestSprite() {
		hitTestSprite.graphics.clear();
		hitTestSprite.graphics.beginFill(0x000000);
	}

	function drawBounds(displayObject:DisplayObject) {
		var bounds = displayObject.getBounds(this);
		var rect = displayObject.getRect(this);
		var origin = displayObject.localToGlobal(new Point());
		var crosshairSize = 4.0;
		
		boundsSprite.graphics.lineStyle(1, 0xff0000);
		boundsSprite.graphics.drawRect(bounds.x, bounds.y, bounds.width, bounds.height);
		boundsSprite.graphics.lineStyle(1, 0x00ff00);
		boundsSprite.graphics.drawRect(rect.x, rect.y, rect.width, rect.height);
		boundsSprite.graphics.lineStyle(1, 0xFF00FF);
		boundsSprite.graphics.moveTo(origin.x, origin.y-crosshairSize);
		boundsSprite.graphics.lineTo(origin.x, origin.y+crosshairSize);
		boundsSprite.graphics.moveTo(origin.x-crosshairSize, origin.y);
		boundsSprite.graphics.lineTo(origin.x+crosshairSize, origin.y);
		if (Std.isOfType(displayObject, DisplayObjectContainer)) {
			var container:DisplayObjectContainer = cast displayObject;
			for (i in 0...container.numChildren) {
				drawBounds(container.getChildAt(i));
			}
		}
	}
}

class TestContainer extends Sprite {
	public var onMouseUp = (e:MouseEvent)->{};
	public var onMouseDown = (e:MouseEvent)->{};
	public var onMouseMove = (e:MouseEvent)->{};
	public var onEnterFrame = (e:Event)->{};
	public var onKeyUp = (e:KeyboardEvent)->{};
	public var onKeyDown = (e:KeyboardEvent)->{};
	public var onDestroy = ()->{};
	public var info:String;
	public var center:Bool = true;

	public function init() {

	}

	public function destroy() {
		if (parent != null) parent.removeChild(this);
		this.onDestroy();
	}
}

class SpinningTest extends TestContainer {
	override public function init() {

		var bmpData = Assets.getBitmapData("assets/texture.png").clone();

		var s = new Sprite();
		s.name = "thing";
		s.graphics.lineStyle(20, 0xff0000);
		s.graphics.beginBitmapFill(bmpData, new Matrix(2,0,0,2, 50, 50));
		s.graphics.drawRect(0, 0, 200, 200);
		s.graphics.endFill();
		addChild(s);

		var i = 0;
		onEnterFrame = function(e:Event) {
			s.rotation = i * 2;
			s.scaleX = s.scaleY = Math.abs(Math.sin(i * Math.PI / 180));
			i++;
		};
	}
}

class Scale9Test extends TestContainer {
	override function init() {
		center = false;
		var bmpData = Assets.getBitmapData("assets/texture.png");

		var s2 = new Sprite();
		s2.graphics.lineStyle(20, 0x269B66, 0.5, true);
		var b2 = bmpData.clone();
		b2.colorTransform(b2.rect, new ColorTransform(1,1,1,0.5));
		s2.graphics.lineBitmapStyle(b2, new Matrix(2,0,0,2));
		s2.graphics.beginBitmapFill(bmpData, new Matrix(1,0,0,1), true, false);
		var width = 200.0;
		var height = 200.0;
		var offset = new Point(100, 100); 
		s2.graphics.drawRoundRect(offset.x, offset.y, width, height, width/4, height/4);
		s2.graphics.endFill();
		var scale9Grid = new Rectangle(offset.x + width/4, offset.y + height/4, width/2, height/2);
		addChild(s2);
		s2.scale9Grid = scale9Grid;
		s2.scaleX = 2.0;
		s2.x = 100.5;
		s2.y = 100.5;

		onEnterFrame = function(e:Event) {
			s2.scaleX = (stage.mouseX - s2.x) / width;
			s2.scaleY = (stage.mouseY - s2.y) / height;
			// trace(s2.scaleX, s2.scaleY);
		};

		// var mask = new Sprite();
		// mask.graphics.beginFill(0xff0000);
		// // mask.graphics.lineStyle(10, 0x0000ff, 1);
		// mask.graphics.drawRect(-100, -100, 200, 200);
		// mask.graphics.endFill();
		// this.addChild(mask);
		// this.mask = mask;
		
		// this.addEventListener(Event.ADDED_TO_STAGE, function(e:Event) {
		// 	mask.startDrag();
		// });
	}
}
class GraphicsTest1 extends TestContainer {
	override public function init() {

		var bmpData = Assets.getBitmapData("assets/texture.png");

		// var b1 = new Bitmap(bmpData);
		// addChild(b1);

		// var b2 = new Bitmap(bmpData);
		// b2.x = 150;
		// addChild(b2);

		// graphics.beginFill(0x00FF00);
		// graphics.drawRect(0, 0, 100, 100);
		// graphics.endFill();

		// 10-point star (5 outer, 5 inner)
		var cx:Float = 250;
		var cy:Float = 250;
		var rOuter:Float = 150;
		var rInner:Float = 60;
		var vertices:Array<Float> = [];

		// Generate star vertices
		for (i in 0...10) {
			var angle = i * Math.PI / 5; // 36 degrees per point
			var r = if (i % 2 == 0) rOuter else rInner;
			vertices.push(Math.round(cx + Math.cos(angle) * r));
			vertices.push(Math.round(cy + Math.sin(angle) * r));
		}

		// Triangulate star manually
		// We'll use center vertex + triangle fan for simplicity
		var indices:Array<Int> = [];
		var centerIndex = Std.int(vertices.length / 2); // next index for center
		vertices.push(cx);
		vertices.push(cy); // add center point

		for (i in 0...10) {
			var next = Std.int((i + 1) % 10);
			indices.push(centerIndex);
			indices.push(i);
			indices.push(next);
		}
		var uvtData:Array<Float> = [];
		for (i in 0...Std.int(vertices.length / 2)) {
			var x = vertices[i * 2];
			var y = vertices[i * 2 + 1];

			var u = (x - (cx - rOuter)) / (2 * rOuter);
			var v = (y - (cy - rOuter)) / (2 * rOuter);

			uvtData.push(u);
			uvtData.push(v);
		}

		// g.drawTriangles(Vector.ofArray(vertices), Vector.ofArray(indices)); // , Vector.ofArray(uvtData)
		vertices = [0, 0, 200, 0, 200, 200, 0, 200];
		indices = [0, 1, 2, 0, 2, 3];
		// uvtData = [0, 0, 1, 0, 1, 1, 0, 1];
		uvtData = [0, 0, 0.5, 0, 1, 2, 0, 1];

		var triSprite = new Sprite();
		triSprite.graphics.beginBitmapFill(bmpData);
		triSprite.graphics.lineStyle(10, 0x006E3D, 0.5);

		var v = Vector.ofArray(vertices);
		var i = Vector.ofArray(indices);
		var uv = Vector.ofArray(uvtData);

		triSprite.graphics.drawTriangles(v, i, uv);
		triSprite.graphics.endFill();
		addChild(triSprite);

		var triSprite2 = new Sprite();
		triSprite2.graphics.beginBitmapFill(bmpData, new Matrix(1, 0, 0, 1, 50, 50));
		triSprite2.graphics.lineStyle(10, 0x006E3D, 0.5);
		triSprite2.graphics.drawTriangles(v, i);
		triSprite2.y = triSprite.y + triSprite.height + 50;
		addChild(triSprite2);

		var s = new Sprite();
		s.x = 200;
		s.y = 200;
		s.graphics.beginBitmapFill(bmpData, new Matrix());
		s.graphics.drawRoundRect(0, 0, 200, 200, 50, 50);
		s.graphics.endFill();
		addChild(s);

		var s2 = new Sprite();
		s2.x = 400;
		s2.y = 400;
		s2.graphics.lineStyle(10, 0x269B66, 1);
		s2.graphics.beginFill(0xff0000);
		s2.graphics.drawRoundRect(0, 0, 200, 200, 50, 50);
		s2.graphics.endFill();
		s2.scale9Grid = new Rectangle(50, 50, 100, 100);
		addChild(s2);

		var s3 = new Sprite();
		s3.x = 200;
		s3.y = 400;
		s3.graphics.lineStyle(10, 0x269B66, 1);
		s3.graphics.beginFill(0xff0000);
		s3.graphics.lineTo(100, 100);
		s3.graphics.lineTo(200, 100);
		s3.graphics.endFill();
		addChild(s3);

		var i = 0;
		onEnterFrame = function(e:Event) {
			s.rotation = i * 2;
			s2.scaleX = s2.scaleY = Math.abs(Math.sin(i * Math.PI / 180));
			i++;
		};

		// var mask = new Sprite();
		// mask.graphics.beginFill(0xff0000);
		// // mask.graphics.lineStyle(10, 0x0000ff, 1);
		// mask.graphics.drawRect(-100, -100, 200, 200);
		// mask.graphics.endFill();
		// this.addChild(mask);
		// this.mask = mask;
		
		// this.addEventListener(Event.ADDED_TO_STAGE, function(e:Event) {
		// 	mask.startDrag();
		// });
	}
}

class CloseGapTest extends TestContainer {
	override public function init() {

		info = "Graphics path with only 2 lineTos should automatically close if filled.";

		var s = new Sprite();
		s.graphics.lineStyle(10, 0x269B66, 1);
		s.graphics.beginFill(0xff0000);
		s.graphics.lineTo(100, 100);
		s.graphics.lineTo(0, 100);
		s.graphics.endFill();
		addChild(s);
	}
}

class FillLineStyleOrderTest extends TestContainer {
	override public function init() {
		var spr = new Sprite();
		spr.graphics.lineStyle(30, 0x00ff00);
		spr.graphics.beginFill(0xff0000);
		spr.graphics.lineTo(0, 100);
		spr.graphics.lineStyle(30, 0x0000ff);
		spr.graphics.lineTo(100, 100);
		spr.graphics.lineStyle();
		spr.graphics.endFill();
		addChild(spr);

		var spr2 = new Sprite();
		spr2.graphics.lineStyle(30, 0x00ff00, 0.5);
		spr2.graphics.beginFill(0xff0000);
		spr2.graphics.lineTo(0, 100);
		spr2.graphics.lineStyle(30, 0x0000ff, 0.5);
		spr2.graphics.lineTo(100, 100);
		spr2.graphics.endFill();
		spr2.graphics.lineStyle();
		addChild(spr2);
		spr2.x = 200;

		var spr3 = new Sprite();
		spr3.graphics.lineStyle(30, 0x00ff00);
		spr3.graphics.lineTo(0, 100);
		spr3.graphics.lineStyle();
		spr3.graphics.beginFill(0xff0000);
		spr3.graphics.drawCircle(0,0,50);
		addChild(spr3);
		spr3.x = 400;
		spr3.scaleX = spr3.scaleY = 2;
	}
}

class SVGTest extends TestContainer {
	override public function init() {

		info = "Bug in svg lib, fix: https://github.com/openfl/svg/pull/78";

		var svg = new SVG(Assets.getText("assets/tiger.svg"));
		var spr = new Sprite();
		svg.render(spr.graphics);
		var data = spr.graphics.readGraphicsData();
		addChild(spr);
	}
}

class Scale9Test2 extends TestContainer {
	override public function init() {

		info = "These 2 rounded rectangles (top with scale9Grid, bottom without) should look identical.";

		var s2 = new Sprite();
		s2.graphics.lineStyle(50, 0xffff00, 1);
		s2.graphics.beginFill(0xff0000);
		s2.graphics.drawRoundRect(0, 0, 200, 200, 25, 25);
		s2.graphics.endFill();
		s2.scale9Grid = new Rectangle(50, 50, 100, 100);
		addChild(s2);
		s2.scaleX = 0.5;

		var s3 = new Sprite();
		s3.graphics.lineStyle(50, 0xffff00, 1);
		s3.graphics.beginFill(0xff0000);
		s3.graphics.drawRoundRect(0, 0, 100, 200, 25, 25);
		s3.graphics.endFill();
		addChild(s3);
		s3.y = s2.height + 10;

		// g.lineStyle(10, 0xFF0000, 1);
		// g.moveTo(vertices[0], vertices[1]);
		// for (i in 1...Std.int(vertices.length / 2)) {
		// 	g.lineTo(vertices[i * 2], vertices[i * 2 + 1]);
		// }
		// g.lineTo(vertices[0], vertices[1]);
	}
}

class MiterBoundsTest extends TestContainer {
	override public function init() {

		var triangle:Sprite = new Sprite();
		triangle.graphics.lineStyle(50, 0xFF0000, 0.5, true, LineScaleMode.NORMAL, CapsStyle.NONE, JointStyle.BEVEL, Math.PI/180*90);

		var triangleSide = 100.0;
		triangle.graphics.beginFill(0x0000ff);
		triangle.graphics.lineTo(0, triangleSide);
		triangle.graphics.lineTo(triangleSide, triangleSide);
		triangle.graphics.lineTo(0, 0);
		triangle.graphics.endFill();

		triangle.graphics.moveTo(150, 150);
		triangle.graphics.lineTo(250, 150);
		triangle.graphics.lineTo(350, 50);
		triangle.graphics.lineTo(450, 150);

		addChild(triangle);

		var ob = new Sprite();

		ob.graphics.lineStyle(20, 0xFF0000, 0.5, true, LineScaleMode.NORMAL, CapsStyle.ROUND, JointStyle.MITER);
		ob.graphics.beginFill(0x00ff00);
		ob.graphics.moveTo(0, 0);
		ob.graphics.cubicCurveTo(0, -50, 100, -50, 100, 0);
		ob.graphics.lineTo(100, 100);
		ob.graphics.endFill();

		ob.graphics.lineStyle(20, 0xFF0000, 0.5, true, LineScaleMode.NORMAL, CapsStyle.ROUND, JointStyle.MITER);
		ob.graphics.beginFill(0x00FF00);
		ob.graphics.moveTo(250, 0);
		ob.graphics.curveTo(300, 0, 300, 50);
		ob.graphics.curveTo(300, 100, 250, 100);
		ob.graphics.curveTo(200, 100, 200, 50);
		ob.graphics.curveTo(200, 0, 250, 0);
		ob.graphics.endFill();
		addChild(ob);
		ob.x = 100;
		ob.y = 200;
	}
}

class GradientTest extends TestContainer {
	override public function init() {
		var oval = new Sprite();
		var w = 400;
		var h = 200;
		var matrix = new Matrix();
		matrix.createGradientBox(w, h, 0, -w/2, -h/2); //  Math.PI/180*45
		matrix.b = matrix.a;
		// oval.graphics.beginFill(0xff0000, 1.0);
		oval.graphics.beginGradientFill(GradientType.RADIAL, [0xFF0000, 0x0000FF], [1.0, 1.0], [0, 255], matrix, SpreadMethod.PAD, InterpolationMethod.RGB, 1);
		oval.graphics.lineStyle(10);
		var matrix2 = new Matrix();
		matrix2.createGradientBox(w, h, 0, -w/2, -h/2); //  Math.PI/180*45
		oval.graphics.lineGradientStyle(GradientType.LINEAR, [0x000000, 0xAA1D5F], [1.0, 1.0], [0, 255], matrix2);
		oval.graphics.drawEllipse(-w/2, -h/2, w, h);
		oval.graphics.endFill();
		this.addChild(oval);

		var i = 0.0;
		onEnterFrame = function(e:Event) {
			oval.rotation = i * 100;
			oval.scaleX = oval.scaleY = 1 + Math.sin(i) * 0.25;
			i += 0.01;
		};
	}
}