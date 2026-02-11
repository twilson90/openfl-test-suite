package;

import openfl.display.SimpleButton;
import format.SVG;
import openfl.Assets;
import openfl.Lib;
import openfl.Vector;
import openfl.display.BitmapData;
import openfl.display.CapsStyle;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.GradientType;
import openfl.display.Graphics;
import openfl.display.GraphicsShader;
import openfl.display.InterpolationMethod;
import openfl.display.JointStyle;
import openfl.display.LineScaleMode;
import openfl.display.Shape;
import openfl.display.SpreadMethod;
import openfl.display.Sprite;
import openfl.display.Stage3D;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import openfl.ui.Keyboard;

@:access(openfl.display.Graphics)
class Main extends Sprite {
	public var currentIndex = 0;
	public var pause = false;
	public var showBounds:Bool = false;
	public var showColorTransform:Bool = false;
	public var showMask:Bool = false;
	public var _scrollRect:Rectangle = new Rectangle(0, 0, 0, 0);
	public var showScrollRect:Bool = false;
	public var showFilters:Bool = false;
	public var showHitTestMarkers:Bool = false;
	public var showOpaqueBackgrounds:Bool = false;
	public var test:Test;
	public var tests:Array<Dynamic> = [
		// SimpleButtonTest,
		// Scale9Test,
		// Crisp1PixelStrokeTest,
		// Scale9Test,
		// GraphicsTest1,
		// Crisp1PixelStrokeTest,
		// BoundsTest,
		// GLBatchTest,
		// MiterBoundsTest,
		// GradientTest,
		// SpinningTest,
		// SVGTest,
		// -----------
		PathAndDrawShapeTest,
		FillLineStyleOrderTest,
		CloseGapTest,
		MiterBoundsTest,
		GradientTest,
		Scale9Test,
		Scale9Test2,
		Scale9Test3,
		GraphicsTest1,
		FlashGlitchy,
		GLBatchTest,
		Crisp1PixelStrokeTest,
		SVGTest,
		DrawQuadsTest,
		SpinningTest,
		ShaderFillTest,
		AlphaMaskTest,
		ComplexMaskTest,
		FrameTimingTest2,
		WeirdScaleGlitchTest,
		// FrameTimingTest1,
	];

	public var testContainer = new Sprite();
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
		0x00FF88 // Mint
	];

	public var maskSprite = new Sprite();

	public var emptyColorTransform = new ColorTransform();
	public var colorTransform = new ColorTransform(0.5, 0.5, 0.5, 1.0);

	static public var bd1:BitmapData;
	static public var bd2:BitmapData;

	public function new() {
		super();

		bd1 = Assets.getBitmapData("assets/texture.png");
		bd2 = new BitmapData(bd1.width, bd1.height, true, 0);
		bd2.copyPixels(bd1, bd1.rect, new Point());
		bd2.colorTransform(bd2.rect, new ColorTransform(1, 1, 1, 0.5));

		addChild(testContainer);
		addChild(boundsSprite);
		addChild(hitTestSprite);

		maskSprite.graphics.beginFill(0, 1);
		maskSprite.graphics.drawEllipse(-200, -100, 400, 200);
		// maskSprite.graphics.drawRect(-200,-100,400,200);
		addChild(maskSprite);

		var stage = Lib.current.stage;

		var funcMap:Array<FuncWrapper> = [
			{
				name: "Previous Test",
				key: Keyboard.LEFT,
				keyName: "Left Arrow",
				func: previousTest
			},
			{
				name: "Next Test",
				key: Keyboard.RIGHT,
				keyName: "Right Arrow",
				func: nextTest
			},
			{
				name: "Toggle OpaqueBackground",
				key: Keyboard.NUMBER_1,
				keyName: "1",
				func: toggleOpaqueBackgrounds,
				value: () -> showOpaqueBackgrounds
			},
			{
				name: "Toggle Bounds",
				key: Keyboard.NUMBER_2,
				keyName: "2",
				func: toggleBounds,
				value: () -> showBounds
			},
			{
				name: "Toggle ColorTransform",
				key: Keyboard.NUMBER_3,
				keyName: "3",
				func: toggleColorTransform,
				value: () -> showColorTransform
			},
			{
				name: "Toggle Mask",
				key: Keyboard.NUMBER_4,
				keyName: "4",
				func: toggleMask,
				value: () -> showMask
			},
			{
				name: "Toggle scrollRect",
				key: Keyboard.NUMBER_5,
				keyName: "5",
				func: toggleScrollRect,
				value: () -> showScrollRect
			},
			{
				name: "Toggle HitTest Markers",
				key: Keyboard.NUMBER_6,
				keyName: "6",
				func: toggleHitTestMarkers,
				value: () -> showHitTestMarkers
			},
			{
				name: "Toggle Filters",
				key: Keyboard.NUMBER_7,
				keyName: "7",
				func: toggleFilters,
				value: () -> showFilters
			},
			{
				name: "Pause Animations",
				key: Keyboard.SPACE,
				keyName: "Space",
				func: togglePause,
				value: () -> pause
			},
			{
				name: "Next Frame",
				key: Keyboard.PERIOD,
				keyName: ">",
				func: _nextFrame
			},
			/* {
				name: "Toggle VSync",
				key: Keyboard.V,
				keyName: "V",
				func: toggleVSync
			},*/
		];
		#if cpp
		var profiling = false;
		function toggleProfiler() {
			if (profiling) {
				cpp.vm.Profiler.stop();
			} else {
				cpp.vm.Profiler.start("profile-" + Std.int(Date.now().getTime()) + ".json");
			}
			profiling = !profiling;
		}
		funcMap.push({
			name: "Toggle CPP Profiler",
			key: Keyboard.P,
			keyName: "P",
			func: toggleProfiler,
			value: () -> profiling
		});
		#end

		var getTestFuncMap = () -> funcMap.concat(test.funcMap);

		stage.addEventListener(KeyboardEvent.KEY_UP, function(e:KeyboardEvent) {
			for (o in getTestFuncMap()) {
				if (e.keyCode == cast o.key) {
					o.func();
				}
			}
		});

		var instructions = new TextField();
		formatTextField(instructions);

		var currentTestTextField = new TextField();
		formatTextField(currentTestTextField);

		var infoTF = new TextField();
		formatTextField(infoTF);
		infoTF.text = " ";

		var ft = new FrameTimeGraph(testContainer);

		addChild(instructions);
		addChild(currentTestTextField);
		addChild(infoTF);
		addChild(ft);

		stage.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent) {
			test.onMouseDown(e);
		});
		stage.addEventListener(MouseEvent.MOUSE_MOVE, function(e:MouseEvent) {
			test.onMouseMove(e);
		});
		stage.addEventListener(MouseEvent.MOUSE_UP, function(e:MouseEvent) {
			test.onMouseUp(e);
		});
		stage.addEventListener(KeyboardEvent.KEY_UP, function(e:KeyboardEvent) {
			test.onKeyDown(e);
		});
		stage.addEventListener(KeyboardEvent.KEY_DOWN, function(e:KeyboardEvent) {
			test.onKeyUp(e);
		});

		var i = 0;
		var hitTest = false;

		addEventListener(Event.ENTER_FRAME, function(e:Event) {
			if (!pause) {
				test.onEnterFrame(e);
				if (showMask) {
					maskSprite.x = stage.mouseX;
					maskSprite.y = stage.mouseY;
					maskSprite.scaleX = maskSprite.scaleY = Math.sin(i * Math.PI / 180);
					maskSprite.rotation = i * 2;
				}
				_scrollRect.width = 500;
				_scrollRect.height = 500;
				_scrollRect.x = Math.sin(i * Math.PI / 180) * 250;
				_scrollRect.y = Math.sin(i * Math.PI / 180) * 250;
				i++;
			}

			var newHitTest = test.hitTestPoint(stage.mouseX, stage.mouseY, true);

			if (showHitTestMarkers) {
				if (newHitTest && !hitTest) {
					hitTestSprite.graphics.drawRect(stage.mouseX - 2, stage.mouseY - 2, 4, 4);
				}
			}

			hitTest = newHitTest;
			// var hardwareDrawable = isHardwareCompatible(current);
			infoTF.text = [
				// "GL: " + (hardwareDrawable == 0 ? "NO" : hardwareDrawable == 1 ? "PARTIAL" : "FULL"),
				"HIT: " + (newHitTest ? "YES" : "NO")
			].join(", ");
			infoTF.y = stage.stageHeight - infoTF.height;

			maskSprite.visible = showMask;
			test.mask = showMask ? maskSprite : null;

			test.scrollRect = showScrollRect ? _scrollRect : null;

			test.transform.colorTransform = showColorTransform ? colorTransform : emptyColorTransform;

			if (test.center) {
				var bounds = test.getBounds(test);
				test.x = Math.floor((stage.stageWidth - bounds.width) / 2.0 - bounds.x);
				test.y = Math.floor((stage.stageHeight - bounds.height) / 2.0 - bounds.y);
			}

			Utils.clear(boundsSprite);

			if (showBounds) {
				var allChildren = Utils.getDescendents(test, true);
				var maskMap = new Map<DisplayObject, DisplayObject>();
				for (c in allChildren) {
					if (c.mask != null) {
						maskMap.set(c.mask, c);
					}
				}
				for (c in allChildren) {
					if (maskMap.exists(c))
						continue;
					if (Std.isOfType(c, Sprite) && cast(c, Sprite).hitArea != null)
						continue;
					drawBounds(c);
				}
			}
			showOpaqueBackground(test, showOpaqueBackgrounds);

			var str = Type.getClassName(tests[currentIndex]);
			if (test.info != null) {
				str += ": " + test.info;
			}
			currentTestTextField.text = str;

			instructions.text = getTestFuncMap().map((f) -> {
				var value = f.value != null ? f.value() : null;
				return f.keyName + " → " + f.name + (value != null ? " (" + (value ? "ON" : "OFF") + ")" : "");
			}).join("\n");
			instructions.x = stage.stageWidth - instructions.width;
			instructions.y = 0;

			ft.x = stage.stageWidth - ft.width;
			ft.y = stage.stageHeight - ft.height;
		});
		loadTest();
	}

	public function loadTest() {
		if (test != null) {
			test.destroy();
		}
		clearHitTestSprite();
		var test_clazz = tests[currentIndex];
		test = cast Type.createInstance(test_clazz, []);
		testContainer.addChild(test);
		test.init();
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

	function toggleScrollRect() {
		showScrollRect = !showScrollRect;
	}

	function toggleHitTestMarkers() {
		showHitTestMarkers = !showHitTestMarkers;
		if (!showHitTestMarkers)
			clearHitTestSprite();
	}

	function toggleFilters() {
		showFilters = !showFilters;
		if (showFilters) {
			testContainer.filters = [new openfl.filters.BlurFilter(5, 5), new openfl.filters.BevelFilter()];
		} else {
			testContainer.filters = [];
		}
	}

	function togglePause() {
		pause = !pause;
	}

	function _nextFrame() {
		pause = false;
		var nextFrame:Dynamic;
		nextFrame = (e:Event) -> {
			removeEventListener(Event.ENTER_FRAME, nextFrame);
			pause = true;
			return;
		};
		addEventListener(Event.ENTER_FRAME, nextFrame);
	}

	function clearHitTestSprite() {
		hitTestSprite.graphics.clear();
		hitTestSprite.graphics.beginFill(0x000000);
	}

	function drawBounds(displayObject:DisplayObject) {
		var g = boundsSprite.graphics;

		var bounds = displayObject.getBounds(this);
		var rect = displayObject.getRect(this);
		var origin = displayObject.localToGlobal(new Point());
		var crosshairSize = 4.0;

		var flags = [];

		// var boundsStr = [
		// 	Std.string(Math.round(bounds.x)),
		// 	Std.string(Math.round(bounds.y)),
		// 	Std.string(Math.round(bounds.width)),
		// 	Std.string(Math.round(bounds.height))
		// ].join(":");
		// flags.push(boundsStr);

		#if !flash
		if (Utils.hasGraphics(displayObject)) {
			var g = Utils.getGraphics(displayObject);
			if (Std.string(stage.window.context.type).indexOf("gl") != -1 && Utils.isHardwareCompatible(g)) {
				flags.push(stage.window.context.type);
			} else {
				#if lime_cairo
				flags.push("cairo");
				#else
				flags.push("canvas");
				#end
			}
		}
		#end

		Utils.roundRect(bounds);
		Utils.roundRect(rect);
		Utils.roundPoint(origin);
		var lineAlpha = 0.75;

		g.lineStyle(1, 0xff0000, lineAlpha);
		g.drawRect(bounds.x, bounds.y, bounds.width, bounds.height);
		g.lineStyle(1, 0x00ff00, lineAlpha);
		g.drawRect(rect.x, rect.y, rect.width, rect.height);
		g.lineStyle(1, 0xFF00FF, lineAlpha);
		g.moveTo(origin.x, origin.y - crosshairSize);
		g.lineTo(origin.x, origin.y + crosshairSize);
		g.moveTo(origin.x - crosshairSize, origin.y);
		g.lineTo(origin.x + crosshairSize, origin.y);

		if (Utils.isValidScale9(displayObject)) {
			g.lineStyle(1, 0x0000FF, lineAlpha);

			var scale9Rect = Utils.getScale9GridRect(displayObject);
			Utils.roundRect(scale9Rect);

			g.moveTo(scale9Rect.left, rect.top);
			g.lineTo(scale9Rect.left, rect.bottom);

			g.moveTo(scale9Rect.right, rect.top);
			g.lineTo(scale9Rect.right, rect.bottom);

			g.moveTo(rect.left, scale9Rect.top);
			g.lineTo(rect.right, scale9Rect.top);

			g.moveTo(rect.left, scale9Rect.bottom);
			g.lineTo(rect.right, scale9Rect.bottom);

			flags.push("scale9");
		}

		g.lineStyle();

		if (flags.length > 0) {
			var tf = new TextField();
			tf.selectable = false;
			tf.defaultTextFormat = new TextFormat("Arial", 12);
			tf.text = flags.join(", ");
			tf.autoSize = TextFieldAutoSize.LEFT;
			tf.x = bounds.x + 1;
			tf.y = bounds.y + 1;
			g.beginFill(0xeeeeee, 0.6);
			g.drawRect(tf.x, tf.y, tf.width, tf.height);
			g.endFill();
			boundsSprite.addChild(tf);
		}
	}
}

typedef FuncWrapper = {
	name:String,
	key:Int,
	keyName:String,
	func:() -> Void,
	?value:() -> Bool
}

class Test extends Sprite {
	public var onMouseUp = (e:MouseEvent) -> {};
	public var onMouseDown = (e:MouseEvent) -> {};
	public var onMouseMove = (e:MouseEvent) -> {};
	public var onEnterFrame = (e:Event) -> {};
	public var onKeyUp = (e:KeyboardEvent) -> {};
	public var onKeyDown = (e:KeyboardEvent) -> {};
	public var onDestroy = () -> {};
	public var info:String;
	public var center:Bool = true;
	public var funcMap:Array<FuncWrapper> = [];

	public function new() {
		super();
		name = Type.getClassName(Type.getClass(this));
	}

	public function init() {}

	public function destroy() {
		if (parent != null)
			parent.removeChild(this);
		this.onDestroy();
	}
}

class BoundsTest extends Test {
	override public function init() {
		center = false;
		var s = new Sprite();
		s.graphics.lineStyle(1, 0.5);
		s.name = "thing";
		var offsetX = 100;
		var offsetY = 100;
		for (x in 1...10) {
			s.graphics.drawRect(offsetX, offsetY, x, x);
			offsetX += x + 10;
		}
		addChild(s);
	}
}

class SpinningTest extends Test {
	override public function init() {
		var s = new Sprite();
		s.name = "thing";
		// s.graphics.lineStyle(20, 0xff0000);
		s.graphics.beginBitmapFill(Main.bd1, new Matrix(2, 0, 0, 2, 50, 50), true, true);
		s.graphics.drawRect(0, 0, 200, 200);
		s.graphics.endFill();
		// s.cacheAsBitmap = true;
		addChild(s);

		var i = 0;
		onEnterFrame = function(e:Event) {
			s.rotation = (i * 2) % 360;
			s.scaleX = s.scaleY = Math.abs(Math.sin(i * Math.PI / 180));
			i++;
		};
	}
}

class SimpleButtonTest extends Test {
	override public function init() {
		var downState = new Sprite();
		downState.graphics.lineStyle(20);
		downState.graphics.beginBitmapFill(Main.bd1, new Matrix(2, 0, 0, 2, 50, 50), true, true);
		downState.graphics.drawRect(0, 0, 200, 200);
		downState.graphics.endFill();
		var overState = new Sprite();
		overState.graphics.lineStyle(10);
		overState.graphics.beginBitmapFill(Main.bd2, new Matrix(2, 0, 0, 2, 50, 50), true, true);
		overState.graphics.drawRect(0, 0, 200, 200);
		overState.graphics.endFill();
		var upState = new Sprite();
		upState.graphics.beginBitmapFill(Main.bd2, new Matrix(2, 0, 0, 2, 50, 50), true, true);
		upState.graphics.drawRect(0, 0, 200, 200);
		upState.graphics.endFill();

		var s = new SimpleButton(upState, overState, downState, upState);
		addChild(s);
	}
}

class Scale9Test extends Test {
	override function init() {
		center = false;
		var s1 = new Sprite();
		s1.name = "s9grid";
		var width = 200.0;
		var height = 200.0;
		var offset = new Point(100, 100);
		var scale9Grid = new Rectangle(offset.x + width / 4, offset.y + height / 4, width / 2, height / 2);

		var strokes = true;
		var useScale9Grid = false;
		var thickness = 50.0;

		var draw = () -> {
			s1.graphics.clear();
			if (strokes) {
				s1.graphics.lineStyle(thickness);
				s1.graphics.lineBitmapStyle(Main.bd2, new Matrix(2, 0, 0, 2));
			}
			s1.graphics.beginBitmapFill(Main.bd1, new Matrix(1, 0, 0, 1), true, false);
			s1.graphics.drawRoundRect(offset.x, offset.y, width, height, width / 4, height / 4);
			s1.graphics.endFill();
		}
		var toggleStrokes = () -> {
			strokes = !strokes;
			draw();
		}
		var toggleScale9Grid = () -> {
			useScale9Grid = !useScale9Grid;
			s1.scale9Grid = useScale9Grid ? scale9Grid : null;
		}

		draw();

		funcMap.push({
			name: "Toggle Stroke",
			key: Keyboard.S,
			keyName: "S",
			func: toggleStrokes,
			value: () -> strokes
		});

		funcMap.push({
			name: "Toggle Scale9Grid",
			key: Keyboard.G,
			keyName: "G",
			func: toggleScale9Grid,
			value: () -> useScale9Grid
		});

		addChild(s1);
		s1.x = 200.5;
		s1.y = 200.5;

		toggleScale9Grid();

		var i = 0;
		onEnterFrame = function(e:Event) {
			s1.scaleX = (stage.mouseX - s1.x) / width;
			s1.scaleY = (stage.mouseY - s1.y) / height;
			// trace(s1.scaleX, s1.scaleY);
		};
	}
}

class WeirdScaleGlitchTest extends Test {
	override function init() {
		var s1 = new Sprite();
		info = "This test shows a weird glitch in Cairo where applying specific scaling results in partial clipping on edges";
		s1.name = "wtf";

		s1.graphics.lineStyle(50);
		s1.graphics.beginFill(0xff0000);
		s1.graphics.drawCircle(0, 0, 100);
		s1.graphics.endFill();

		s1.graphics.lineStyle(1, 0x00ff00);
		s1.graphics.drawCircle(0, 0, 100);

		var unfucked = false;
		var axisSwitch = false;

		var toggleAxis = () -> {
			axisSwitch = !axisSwitch;
		}

		funcMap.push({
			name: "Switch Axis",
			key: Keyboard.A,
			keyName: "A",
			func: toggleAxis,
			value: () -> axisSwitch
		});
		var sx = 2.7925;
		var sy = 0.3575;
		// var sx = 2.2075;
		// var sy = 0.4475;

		var inc = 0.01;

		funcMap.push({
			name: "ScaleX+",
			key: Keyboard.X,
			keyName: "X",
			func: () -> sx += inc,
		});
		funcMap.push({
			name: "ScaleX-",
			key: Keyboard.Z,
			keyName: "Z",
			func: () -> sx -= inc,
		});

		funcMap.push({
			name: "ScaleY+",
			key: Keyboard.Y,
			keyName: "Y",
			func: () -> sy += inc,
		});
		funcMap.push({
			name: "ScaleY-",
			key: Keyboard.T,
			keyName: "T",
			func: () -> sy -= inc,
		});

		addChild(s1);

		onEnterFrame = function(e:Event) {
			if (axisSwitch) {
				s1.scaleX = sy;
				s1.scaleY = sx;
			} else {
				s1.scaleX = sx;
				s1.scaleY = sy;
			}
		};
	}
}

class Scale9Test2 extends Test {
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

class Scale9Test3 extends Test {
	override function init() {
		center = false;

		var s = new Sprite();
		var size = 600.0;
		var offset = 60.0;

		var s9g = new Rectangle(offset, offset, size - (offset * 2), size - (offset * 2));

		s.graphics.clear();

		var drawRect = (x:Float, y:Float, w:Float, h:Float) -> {
			var m = new Matrix();
			m.createBox(w / Main.bd1.width, h / Main.bd1.height, 0, x, y);
			s.graphics.beginBitmapFill(Main.bd1, m, true, false);
			s.graphics.drawRect(x, y, w, h);
			s.graphics.endFill();
		}
		drawRect(0, 0, offset, offset);
		drawRect(size / 2, 0, size / 2, offset);
		drawRect(size / 6, 0, size / 6, size / 6);
		drawRect(0, size / 6, offset, size / 6);
		drawRect(0, size - (size / 6), size / 6, size / 6);
		drawRect(size / 3, size - offset, size / 3, offset);
		drawRect((size - (size / 6)) / 2, (size - (size / 6)) / 2, size / 6, size / 6); // middle
		drawRect(size - (size / 6), size / 6, size / 6, size / 6);
		drawRect(size - offset, size - offset, offset, offset); // bottom right

		// Flash complains if we do this before drawing the graphics.
		s.scale9Grid = s9g;

		var container = new Sprite();
		addChild(container);

		container.addChild(s);

		x = 50;
		y = 50;

		onEnterFrame = function(e:Event) {
			s.scaleX = (stage.mouseX - x) / size;
			s.scaleY = (stage.mouseY - y) / size;
		};
	}
}

class Crisp1PixelStrokeTest extends Test {
	override function init() {
		var s1 = new Sprite();
		center = false;

		info = "The line should be crisp and not antialiased.";

		addChild(s1);

		// var s2 = new Sprite();
		// s2.graphics.lineStyle(0.5);
		// s2.graphics.moveTo(50.5, 50.5);
		// s2.graphics.lineTo(150.5, 50.5);
		// addChild(s2);

		onEnterFrame = function(e:Event) {
			var offset = 100;
			s1.graphics.clear();
			s1.graphics.lineStyle(1, 0.5);
			s1.graphics.drawRect(offset, offset, stage.mouseX - offset, stage.mouseY - offset);
		};
	}
}

class GraphicsTest1 extends Test {
	override public function init() {
		// g.drawTriangles(Vector.ofArray(vertices), Vector.ofArray(indices)); // , Vector.ofArray(uvtData)
		var vertices:Array<Float> = [0, 0, 200, 0, 200, 200, 0, 200];
		var indices = [0, 1, 2, 0, 2, 3];
		// uvtData = [0, 0, 1, 0, 1, 1, 0, 1];
		var uvtData:Array<Float> = [0, 0, 0.5, 0, 1, 2, 0, 1];

		var triSprite = new Sprite();
		triSprite.graphics.beginBitmapFill(Main.bd1);
		triSprite.graphics.lineStyle(10, 0x006E3D, 0.5);

		var v = Vector.ofArray(vertices);
		var i = Vector.ofArray(indices);
		var uv = Vector.ofArray(uvtData);

		triSprite.graphics.drawTriangles(v, i, uv);
		triSprite.graphics.endFill();
		addChild(triSprite);

		var triSprite2 = new Sprite();
		triSprite2.graphics.beginBitmapFill(Main.bd1, new Matrix(1, 0, 0, 1, 50, 50));
		triSprite2.graphics.lineStyle(10, 0x006E3D, 0.5);
		triSprite2.graphics.drawTriangles(v, i);
		triSprite2.y = triSprite.y + triSprite.height + 50;
		addChild(triSprite2);

		var s = new Sprite();
		s.x = 200;
		s.y = 200;
		s.graphics.beginBitmapFill(Main.bd1, new Matrix());
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
			s.rotation = (i * 2) % 360;
			s2.scaleX = s2.scaleY = Math.abs(Math.sin(i * Math.PI / 180));
			i++;
		};
	}
}

class CloseGapTest extends Test {
	override public function init() {
		info = "Graphics path with only 2 lineTos should automatically close if filled.";

		var s = new Sprite();
		s.graphics.lineStyle(10, 0x269B66, 1);
		s.graphics.beginFill(0xff0000);
		s.graphics.lineTo(100, 100);
		s.graphics.lineTo(0, 100);
		// s.graphics.endFill();
		addChild(s);
	}
}

class FlashGlitchy extends Test {
	override public function init() {
		info = "Unusual behavior in flash target, the graphics are corrupted by this unusual command order. Resize window in Flash Player to observe.";

		var spr2 = new Sprite();
		spr2.graphics.moveTo(100, 0);
		spr2.graphics.lineTo(0, 100);
		spr2.graphics.beginFill(0x990000);
		spr2.graphics.lineTo(100, 100);
		spr2.graphics.endFill();
		addChild(spr2);
	}
}

class PathAndDrawShapeTest extends Test {
	override public function init() {
		var spr = new Sprite();

		spr.graphics.lineStyle(10, 0x0000ff);
		spr.graphics.moveTo(0, 0);
		spr.graphics.lineTo(100, 0);
		spr.graphics.lineStyle(10, 0x00ff00);
		spr.graphics.beginFill(0xff0000);
		spr.graphics.lineTo(100, 100);

		addChild(spr);
		spr.x = -200;

		var spr2 = new Sprite();

		spr2.graphics.moveTo(0, 0);
		spr2.graphics.lineStyle(10, 0x00ff00);
		spr2.graphics.moveTo(0, 0);
		spr2.graphics.lineTo(0, 100);
		spr2.graphics.lineTo(100, 0);

		spr2.graphics.beginFill(0xff0000);
		spr2.graphics.lineStyle(10, 0x0000ff);
		spr2.graphics.moveTo(100, 0);
		spr2.graphics.lineTo(200, 100);
		spr2.graphics.lineTo(200, 0);
		spr2.graphics.lineStyle();
		spr2.graphics.endFill();

		spr2.graphics.beginFill(0x990000);
		spr2.graphics.drawCircle(300, 100, 100);
		spr2.graphics.lineTo(300, 0);
		spr2.graphics.lineTo(400, 0);
		spr2.graphics.endFill();

		spr2.graphics.beginFill(0x990000);
		spr2.graphics.lineStyle(10, 0);
		spr2.graphics.drawCircle(100, 300, 100);
		spr2.graphics.lineStyle();
		spr2.graphics.drawCircle(200, 300, 100);
		spr2.graphics.lineStyle(10, 0);
		spr2.graphics.drawCircle(300, 300, 100);

		addChild(spr2);

		var spr3 = new Sprite();
		spr3.graphics.lineStyle(10, 0x432987);
		spr3.graphics.beginFill(0x990000);
		spr3.graphics.drawCircle(0, 0, 100);
		spr3.graphics.lineTo(200, 0);
		spr3.graphics.beginFill(0x129900);
		spr3.graphics.drawCircle(0, 100, 100);
		spr3.graphics.lineTo(200, 100);
		spr3.graphics.beginFill(0x001799);
		spr3.graphics.drawCircle(0, 200, 100);
		spr3.graphics.lineTo(200, 200);
		spr3.x = -100;
		spr3.y = 200;

		addChild(spr3);
	}
}

class FillLineStyleOrderTest extends Test {
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
		spr3.graphics.drawCircle(0, 0, 50);
		addChild(spr3);
		spr3.x = 400;
		spr3.scaleX = spr3.scaleY = 2;
	}
}

class SVGTest extends Test {
	override public function init() {
		info = "Bug in svg lib, fix: https://github.com/openfl/svg/pull/78";

		var spr = new TigerSprite();
		addChild(spr);

		var scale9Grid = false;
		var rotation = false;
		var scaling = false;
		function toggleScale9Grid() {
			scale9Grid = !scale9Grid;
		}
		function toggleRotation() {
			rotation = !rotation;
		}
		function toggleScaling() {
			scaling = !scaling;
		}
		function toggleCacheAsBitmap() {
			spr.cacheAsBitmap = !spr.cacheAsBitmap;
		}
		funcMap.push({
			name: "Toggle Scale9Grid",
			key: Keyboard.S,
			keyName: "S",
			func: toggleScale9Grid,
			value: () -> scale9Grid
		});
		funcMap.push({
			name: "Toggle Rotation",
			key: Keyboard.R,
			keyName: "R",
			func: toggleRotation,
			value: () -> rotation
		});
		funcMap.push({
			name: "Toggle Scaling",
			key: Keyboard.G,
			keyName: "G",
			func: toggleScaling,
			value: () -> scaling
		});
		funcMap.push({
			name: "Toggle CacheAsBitmap",
			key: Keyboard.C,
			keyName: "C",
			func: toggleCacheAsBitmap,
			value: () -> spr.cacheAsBitmap
		});

		var i = 0;
		onEnterFrame = (e:Event) -> {
			i++;
			if (rotation) {
				spr.rotation = (i / 60.0 * 180.0) % 360;
			}
			if (scaling) {
				spr.scaleX = 0.5 + Math.abs(Math.sin(i * 0.01)) * 0.5;
				spr.scaleY = 0.5 + Math.abs(Math.cos(i * 0.01)) * 0.5;
			} else if (scale9Grid) {
				var r = spr.getRect(spr);
				r.inflate(-r.width / 4, -r.height / 4);
				spr.scale9Grid = r;
				spr.scaleX = 0.5 + Math.abs(Math.sin(i * 0.01)) * 0.5;
				spr.scaleY = 0.5 + Math.abs(Math.cos(i * 0.01)) * 0.5;
			} else {
				spr.scale9Grid = null;
				spr.scaleX = spr.scaleY = 1.0;
			}
		};
	}
}

class TigerSprite extends Sprite {
	public function new() {
		super();
		var svg = new SVG(Assets.getText("assets/tiger.svg"));
		svg.render(graphics);
	}
}

class DrawQuadsTest extends Test {
	override public function init() {
		var g = graphics;

		var rects:Array<Float> = [
			  0,   0, 100, 100,
			200, 200, 100, 100,
		];
		var indices = [0, 0, 1, 1];
		var transforms:Array<Float> = [
			     1,      0,       0,      1,   0,   0,
			     1,      0,       0,      1, 200,   0,
			0.7071, 0.7071, -0.7071, 0.7071,   0, 200,
			0.7071, 0.7071, -0.7071, 0.7071, 200, 200,
		];
		// g.lineStyle(10, 0xff0000);
		g.beginBitmapFill(Main.bd1, new Matrix(1, 0, 0, 1, 0, 0));
		// g.beginFill(0x00FF00);
		g.drawQuads(Vector.ofArray(rects), Vector.ofArray(indices), Vector.ofArray(transforms));
		g.endFill();
		// var i = 0;
		// onEnterFrame = (e:Event) -> {
		// 	this.scaleX = this.scaleY = 1.0 + Math.abs(Math.sin(i * 0.01)) * 0.5;
		// 	i++;
		// };
	}
}

class MiterBoundsTest extends Test {
	override public function init() {
		info = "Note: The bevel in miter joints that exceed the miter limit are shallower in Flash. This cannot be recreated in Canvas / Cairo";

		var triangleSide = 100.0;
		var t1:Sprite = new Sprite();
		t1.graphics.lineStyle(50, 0xFF0000, 0.5, true, LineScaleMode.NORMAL, CapsStyle.NONE, JointStyle.BEVEL, Math.PI / 180 * 90);
		t1.graphics.beginFill(0x0000ff);
		t1.graphics.lineTo(0, triangleSide);
		t1.graphics.lineTo(triangleSide, triangleSide);
		t1.graphics.endFill();
		addChild(t1);

		var t2:Sprite = new Sprite();
		t2.graphics.lineStyle(50, 0xFF0000, 0.5, true, LineScaleMode.NORMAL, CapsStyle.NONE, JointStyle.BEVEL);
		t2.graphics.lineTo(0, triangleSide);
		t2.graphics.lineTo(triangleSide, triangleSide);
		t2.graphics.lineTo(0, 0);
		addChild(t2);
		t2.x = 150;

		var t3:Sprite = new Sprite();
		t3.graphics.lineStyle(50, 0xFF0000, 0.5, true, LineScaleMode.NORMAL, CapsStyle.NONE, JointStyle.MITER, Math.PI);
		t3.graphics.lineTo(0, triangleSide);
		t3.graphics.lineTo(triangleSide, triangleSide);
		t3.graphics.lineTo(0, 0);
		addChild(t3);
		t3.x = 300;

		var t4:Sprite = new Sprite();
		t4.graphics.lineStyle(50, 0xFF0000, 0.5, true, LineScaleMode.NORMAL, CapsStyle.NONE, JointStyle.MITER, Math.PI / 180 * 90);
		t4.graphics.lineTo(0, triangleSide);
		t4.graphics.lineTo(triangleSide, triangleSide);
		t4.graphics.lineTo(0, 0);
		addChild(t4);
		t4.x = 450;

		var line:Sprite = new Sprite();
		line.graphics.lineStyle(50, 0xFF0000, 0.5, true, LineScaleMode.NORMAL, CapsStyle.NONE, JointStyle.BEVEL, Math.PI / 180 * 90);
		line.graphics.moveTo(0, 0);
		line.graphics.lineTo(100, 0);
		line.graphics.lineTo(200, 100);
		line.graphics.lineTo(300, 0);
		addChild(line);
		line.x = 300;
		line.y = 200;

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
		ob.x = 0;
		ob.y = 200;

		var createX = (capsStyle:CapsStyle) -> {
			var ob = new Sprite();
			ob.graphics.lineStyle(20, 0xFF0000, 0.5, true, LineScaleMode.NORMAL, capsStyle, JointStyle.MITER);
			ob.graphics.moveTo(0, 0);
			ob.graphics.lineTo(100, 100);
			ob.graphics.moveTo(100, 0);
			ob.graphics.lineTo(0, 100);
			addChild(ob);
			return ob;
		}
		var ob2 = createX(CapsStyle.NONE);
		ob2.x = 0;
		ob2.y = 400;

		var ob3 = createX(CapsStyle.ROUND);
		ob3.x = 200;
		ob3.y = 400;

		var ob4 = createX(CapsStyle.SQUARE);
		ob4.x = 400;
		ob4.y = 400;
	}
}

class GradientTest extends Test {
	override public function init() {
		var oval = new Sprite();
		var w = 400;
		var h = 200;
		var matrix = new Matrix();
		matrix.createGradientBox(w, h, 0, -w / 2, -h / 2); //  Math.PI/180*45
		matrix.b = matrix.a;
		var matrix2 = new Matrix();
		matrix2.createGradientBox(w, h, 0, -w / 2, -h / 2); //  Math.PI/180*45
		// oval.graphics.beginFill(0xff0000, 1.0);

		var strokes = true;
		var draw = () -> {
			oval.graphics.clear();
			oval.graphics.beginGradientFill(GradientType.RADIAL, [0xFF0000, 0x0000FF], [1.0, 1.0], [0, 255], matrix, SpreadMethod.PAD,
				InterpolationMethod.RGB, 1);
			if (strokes) {
				oval.graphics.lineStyle(10);
				oval.graphics.lineGradientStyle(GradientType.LINEAR, [0x000000, 0xAA1D5F], [1.0, 1.0], [0, 255], matrix2);
			} else {}
			oval.graphics.drawEllipse(-w / 2, -h / 2, w, h);
			oval.graphics.endFill();
		}
		this.addChild(oval);

		var toggleStrokes = () -> {
			strokes = !strokes;
			draw();
		}

		draw();

		funcMap.push({
			name: "Toggle Stroke",
			key: Keyboard.S,
			keyName: "S",
			func: toggleStrokes
		});

		var i = 0.0;
		onEnterFrame = function(e:Event) {
			oval.rotation = (i * 100) % 360;
			oval.scaleX = oval.scaleY = 1 + Math.sin(i) * 0.25;
			i += 0.01;
		};
	}
}

class AlphaMaskTest extends Test {
	override public function init() {
		var w = 400;
		var h = 400;

		var spr = new Sprite();
		spr.graphics.beginBitmapFill(Main.bd1, new Matrix(1, 0, 0, 1, 0, 0));
		spr.graphics.drawRect(0, 0, w, h);
		spr.cacheAsBitmap = true;
		addChild(spr);

		var oval = new Sprite();
		var gm = new Matrix();
		gm.createGradientBox(w, h, Math.PI / 2.0, 0, 0);
		oval.graphics.beginGradientFill(GradientType.LINEAR, [0xffffff, 0xffffff], [0.0, 1.0], [0, 255], gm);
		oval.graphics.drawEllipse(0, 0, w, h);
		oval.graphics.endFill();
		oval.cacheAsBitmap = true;
		addChild(oval);

		spr.mask = oval;
	}
}

class ComplexMaskTest extends Test {
	override public function init() {
		info = "Due to some paths having a different winding order, these become holes in the mask in Cairo/Canvas/Flash. However hitTestPoint returns false in these holes for Flash, but true for Cairo/Canvas";

		var tiger = new TigerSprite();
		tiger.width = 800;
		tiger.scaleY = tiger.scaleX;
		addChild(tiger);
		var r = tiger.getBounds(this);

		var spr = new Sprite();
		spr.graphics.beginBitmapFill(Main.bd1, new Matrix(1, 0, 0, 1, 0, 0));
		spr.graphics.drawRect(r.x, r.y, r.width, r.height);
		addChild(spr);

		spr.mask = tiger;
	}
}

class GLBatchTest extends Test {
	override public function init() {
		var spr = new Sprite();
		var g = spr.graphics;

		info = "This test attempts to draw a number of primitives with the least number of GL draw calls.";

		g.beginBitmapFill(Main.bd1);

		var gap = 50.0;
		var h = 100.0;
		var w = 100.0;
		var x = 0.0;
		var y = 0.0;

		// row 1
		g.drawRect(x, y, w, h);
		g.drawRect(x + 25, y + 25, w, h);
		g.drawRect(x + 50, y + 50, w, h);
		x += w + gap;
		g.drawCircle(x + w / 2, y + h / 2, w / 2);
		x += w + gap;
		g.drawEllipse(x, y, w, h);
		x += w + gap;
		g.drawRoundRect(x, y, w, h, 25, 25);

		// // row 2, quads
		y += h + gap;
		var rects:Array<Float> = [0, 0, w, h];
		var indices = [0, 0, 0, 0];
		var transforms:Array<Float> = [
			1, 0, 0, 1,             0, y,
			1, 0, 0, 1,     (gap + w), y,
			1, 0, 0, 1, (gap + w) * 2, y,
			1, 0, 0, 1, (gap + w) * 3, y,
		];
		g.drawQuads(Vector.ofArray(rects), Vector.ofArray(indices), Vector.ofArray(transforms));

		// row 3, tris
		x = 0.0;
		y += h + gap;
		var vertices:Array<Float> = [];
		var indices:Array<Int> = [];
		for (xc in 0...4) {
			x = (w + gap) * xc;
			var left = x;
			var top = y;
			var right = x + w;
			var bottom = y + h;
			vertices = vertices.concat([left, top, right, top, right, bottom, left, bottom]);
			indices = indices.concat([xc * 4, xc * 4 + 1, xc * 4 + 2, xc * 4, xc * 4 + 2, xc * 4 + 3]);
		}
		g.drawTriangles(Vector.ofArray(vertices), Vector.ofArray(indices));

		onEnterFrame = function(e:Event) {
			spr.width = stage.mouseX + 0.5;
			spr.height = stage.mouseY + 0.5;
		};

		addChild(spr);
	}
}

class FrameTimingTest1 extends Test {
	override public function init() {
		var g = graphics;
		var i = 0;
		var arcSteps = 120;

		onEnterFrame = function(e:Event) {
			i++;
			var phase = Std.int(i / arcSteps);
			var t = i % arcSteps;

			var headStep:Int;
			var tailStep:Int;

			if ((phase & 1) == 0) {
				headStep = phase * arcSteps + t;
				tailStep = phase * arcSteps;
			} else {
				headStep = (phase + 1) * arcSteps;
				tailStep = phase * arcSteps + t;
			}

			var head = (headStep / arcSteps) * Math.PI * 2;
			var tail = (tailStep / arcSteps) * Math.PI * 2;
			//
			g.clear();
			g.beginFill(0x222222);
			g.drawCircle(0, 0, 300);
			var d = i % 2;
			if (d == 0)
				g.beginFill(0xff0000);
			else
				g.beginFill(0x00ff00);
			//
			Utils.drawArc(g, 0, 0, 300, tail, head);
		};
	}
}

class FrameTimingTest2 extends Test {
	override public function init() {
		var i = 0;
		var arcSteps = 120;
		var spr = new Sprite();
		var g = spr.graphics;
		addChild(spr);

		for (i in 0...3) {
			var c = new Sprite();
			c.graphics.beginFill(0x0000ff);
			c.graphics.drawRect(0, 0, 100, 100);
			c.x = i * 100;
			c.y = i * 100;
			c.alpha = 0.5;
			spr.addChild(c);
		}

		onEnterFrame = function(e:Event) {
			i++;
			spr.rotation = (i / arcSteps) * 360;
			var d = i % 2;
			g.clear();
			if (d == 0)
				g.beginFill(0xff0000);
			else
				g.beginFill(0x00ff00);
			g.drawRect(-300, -300, 600, 600);
		};
	}
}

class ShaderFillTest extends Test {
	override public function init() {
		var width = 500;
		var height = 500;

		var spr = new Sprite();
		addChild(spr);

		var bd = new BitmapData(2, 2, true, 0xFFFF0000);
		bd.setPixel32(1, 1, 0xFFFFFFFF);

		#if !flash
		var shader = new GraphicsShader();
		shader.data.bitmap.input = bd;
		shader.data.bitmap.wrap = 2;
		spr.graphics.beginShaderFill(shader);
		spr.graphics.drawTriangles(new Vector(0, false, [
			      0.0,  0.0,
			width / 2,  0.0,
			      0.0, height
		]));
		spr.graphics.endFill();
		#end

		spr.graphics.beginBitmapFill(bd);
		spr.graphics.drawTriangles(new Vector(0, false, [
			    width,  0.0,
			width / 2,  0.0,
			    width, height
		]));
		spr.graphics.endFill();
	}
}

class GraphicsTest2 extends Test {
	override public function init() {
		var s2 = new Sprite();
		s2.x = 400;
		s2.y = 400;
		s2.graphics.lineStyle(10, 0x269B66, 1);
		s2.graphics.beginFill(0xff0000);
		s2.graphics.drawRoundRect(0, 0, 200, 200, 50, 50);
		s2.graphics.endFill();
		s2.scale9Grid = new Rectangle(50, 50, 100, 100);
		addChild(s2);

		var i = 0;
		onEnterFrame = function(e:Event) {
			s2.scaleX = s2.scaleY = 0;
			i++;
		};
	}
}
