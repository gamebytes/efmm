package worlds 
{
	import entities.Arrow;
	import entities.Mover;
	import entities.Pitfall;
	import entities.Player;
	import entities.SoundEntity;
	import entities.TickableEntity;
	import flash.filters.ConvolutionFilter;
	import flash.geom.Point;
	import flash.media.Sound;
	import net.flashpunk.Entity;
	import net.flashpunk.FP;
	import net.flashpunk.graphics.Image;
	import net.flashpunk.graphics.Text;
	import net.flashpunk.graphics.Tilemap;
	import net.flashpunk.masks.Grid;
	import net.flashpunk.utils.Input;
	import net.flashpunk.utils.Key;
	import net.flashpunk.World;
	import sounds.Note;
	
	/**
	 * Copyright 2011 The Game Studio (http://www.thegamestudio.net). All rights reserved.
	 * @author Zachary Weston Lewis
	 */
	public class GameWorld extends World 
	{
		protected var _doIce:Boolean;
		protected var _multiplierDirection:Point;
		protected var _doMultiplier:Boolean;
		protected var _lastNote:Number;
		protected var _currentScale:Array;
		protected var _currentTime:Number;
		protected var _bpm:Number;
		protected var _bassline:Note;
		protected var _player:Player;
		protected var _cursor:Image;
		protected var _cursorArmed:Boolean;
		protected var _arrowCount:uint;
		protected var _tiles:Tilemap;
		protected var _grid:Vector.<Vector.<uint>>;
		protected var _moveMultiplier:uint;
		protected var _multiplierText:Text;
		protected var _isIce:Boolean;
		
		public function get Tiles():Vector.<Vector.<uint>>
		{
			return _grid;
		}
		
		public function GameWorld(map:Class) 
		{
			_bpm = 120;
			_currentTime = 0;
			_cursorArmed = false;
			_lastNote = 0;
			_cursor = new Image(Assets.GFX_CURSOR);
			_cursor.alpha = 0.8;
			Input.define(C.KEY_ACTION, [Key.ESCAPE]);
			loadLevel(map);
			V.ArrowLocation = 0;
			_arrowCount = 0;
			_moveMultiplier = 1;
			_doMultiplier = false;
			_isIce = false;
			_doIce = false;
		}
		
		override public function begin():void 
		{
			super.begin();
			add(_player);
			for (var i:uint = 0; i <= FP.screen.width; i += 16)
			{
				var a:Arrow = Arrow(add(new Arrow(GetNextArrowLocation())));				
			}
			addGraphic(_tiles,0,0,0);
			addGraphic(_cursor, -1, 64, FP.screen.height - 16);
			_multiplierText = new Text("",0,0,{align:"center", width:16})
			addGraphic(_multiplierText, -1, 65, FP.screen.height - 17);
		}
		
		override public function update():void 
		{
			super.update();
			
			if (_moveMultiplier > 1)
			{
				_multiplierText.text = _moveMultiplier.toString();
			}
			else
			{
				_multiplierText.text = "";
			}
			
			_currentTime += FP.elapsed;
			V.ArrowLocation -= FP.elapsed * ArrowSpeed;
			if (_currentTime > SecondsPerBeat)
			{
				tick();
				_currentTime -= SecondsPerBeat;
			}
			
			if (Input.pressed(C.KEY_ACTION))
			{
				// Arm our zapper.
				_cursor.color = 0xE12DDD;
				_cursor.alpha = 1;
				_cursorArmed = true;				
			}
			
			if (_cursorArmed)
			{
				_cursor.color = 0xE12ddd;
			}
			else if (_isIce)
			{
				_cursor.color = 0x50A3FE;
			}
			else
			{
				_cursor.color = 0xFFFFFF;
			}
		}
		
		protected function tick():void
		{
			var arrows:Vector.<Arrow> = new Vector.<Arrow>();
			add(new SoundEntity(_currentScale[0]/2,0,0.2));
			addArrow();
			var ta:Vector.<TickableEntity> = new Vector.<TickableEntity>();
			getClass(TickableEntity, ta);
			for each(var e:TickableEntity in ta)
			{
				e.tick()
			}
			// We need to update our enemies.
			if (_cursorArmed || _doMultiplier || _doIce)
			{
				// Alright! We're going to fire off the move command, and play a note.
				playRandomNote(_currentScale);
				_cursor.alpha = 0.8;
				_cursorArmed = false;
				
				if (_doIce || _doMultiplier)
				{
					if (_doMultiplier)
					{
						_moveMultiplier--;
						_player.move(_multiplierDirection);
						if (_moveMultiplier < 1)
						{
							_doMultiplier = false;
							_moveMultiplier = 1;
						}
					}
					if (_doIce)
					{
						_doIce = _player.move(_multiplierDirection);
						_isIce = false;
					}
				}				
				else
				{
					// Get the fired thing.
					var a:Arrow = Arrow(this.collidePoint(C.TYPE_ARROW, 72, FP.screen.height - 8));
					if (a != null)
					{
						a.used();
						if (a.BlockType < 4)
						{
							if (_moveMultiplier > 1 || _isIce)
							{
								_multiplierDirection = a.Direction;
								if (_moveMultiplier > 1)
								{
									_doMultiplier = true;
									_moveMultiplier--;
								}
								if (_isIce) _doIce = true;
							}
							_player.move(a.Direction);
						}
						else if (a.BlockType == 4)
						{
							// Speed up.
							_bpm += 10;
							if (_bpm > 160) _bpm = 160;
						}
						else if (a.BlockType == 5)
						{
							// Slow down.
							_bpm -= 10;
							if (_bpm < 80) _bpm = 80;
						}
						else if (a.BlockType == 6)
						{
							// Freeze block! Chillin!
							_isIce = true;
							_cursor.color = 0x50A3FE;
						}
						else if (a.BlockType == 7)
						{
							// Move multiplier!!!
							_moveMultiplier *= 2;
							if (_moveMultiplier > 8) _moveMultiplier = 8;
						}
					}
				}
			}
		}
		
		public function playRandomNote(scale:Array = null, duration:Number = 0):void
		{
			if (scale == null) scale = _currentScale;
			add(new SoundEntity(FP.choose(scale), duration, 0.5));
		}
		
		protected function get SecondsPerBeat():Number
		{
			return 60 / _bpm;
		}
		
		protected function get ArrowSpeed():Number
		{
			return 16 / SecondsPerBeat;
		}
		
		protected function addArrow():void
		{
			add(new Arrow(GetNextArrowLocation()));
		}
		
		protected function GetNextArrowLocation():int
		{
			return _arrowCount++ * 16;
		}
		
		protected function loadLevel(map:Class):void
		{
			var xml:XML = FP.getXML(map);
			var o:XML;
			_tiles = new Tilemap(Assets.GFX_TILES, uint(xml.width), uint(xml.height), 16, 16);
			_grid = new Vector.<Vector.<uint>>();
			for (var i:uint = 0; i < 20; i++)
			{
				_grid[i] = new Vector.<uint>();
				for (var j:uint = 0; j < 14; j++)
				{
					_grid[i][j] = 0;
				}
			}
			for each(o in xml.tiles.tile)
			{
				var tileCol:uint = uint(o.@x)/16;
				var tileRow:uint = uint(o.@y)/16;
				var tileType:uint = uint(o.@tx / 16);
				if (tileCol >= 0 && tileCol < 20 && tileRow >= 0 && tileRow < 14)
				{
					_tiles.setTile(tileCol, tileRow, tileType);
					_grid[tileCol][tileRow] = tileType + 1;
				}
			}
			
			for each(o in xml.actors.mover)
			{
				add(new Mover(new Point(uint(o.@x) / 16, uint(o.@y) / 16), new Point(int(o.@horizontal), int(o.@vertical))));
			}
			
			for each(o in xml.actors.pitfall)
			{
				add(new Pitfall(new Point(uint(o.@x) / 16, uint(o.@y) / 16), o.@openDuration, o.@closedDuration, o.@initialDelay, o.@startOpen=="true"));
			}
			
			_player = new Player(new Point(uint(xml.actors.player.@x) / 16, uint(xml.actors.player.@y) / 16));
			
			SetLevelScale(xml.@scale);
			
		}
		
		public function SetLevelScale(scale:String):void
		{
			_currentScale = C["SCALE_" + scale];			
			trace("Level scale is " + scale);
		}
		
		override public function end():void 
		{
			removeAll();
			super.end();
		}
	}

}