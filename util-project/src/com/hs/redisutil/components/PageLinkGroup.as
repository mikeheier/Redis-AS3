//------------------------------------------------------------------------------
//	Michael Heier 
//------------------------------------------------------------------------------

package com.hs.redisutil.components
{
	import com.hs.redisutil.events.PageLinkGroupEvent;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import mx.core.IVisualElement;
	import spark.components.Group;
	import spark.components.Label;
	import spark.layouts.HorizontalLayout;
	import spark.layouts.VerticalLayout;

	[Style( name = "selectedColor" , inherit = "yes" , type = "uint" )]
	[Event( name = "activePageSelected" , type = "com.hs.redisutil.events.PageLinkGroupEvent" )]
	[Event( name = "pageSelected" , type = "com.hs.redisutil.events.PageLinkGroupEvent" )]
	public class PageLinkGroup extends Group
	{

		//=================================
		// constructor 
		//=================================

		public function PageLinkGroup()
		{
			super();
			_pages = Vector.<uint>( [] );
			clipAndEnableScrolling = true;
		}


		//=================================
		// public properties 
		//=================================

		protected var _direction : String = "horizontal";

		public function get direction() : String
		{
			return _direction;
		}

		[Inspectable( category = "General" , enumeration = "horizontal,vertical,none" , defaultValue = "horizontal" )]
		public function set direction( value : String ) : void
		{
			_direction = value;
		}

		protected var _pages : Vector.<uint>;

		[Bindable( event = "pagesChanged" )]
		public function get pages() : Vector.<uint>
		{
			return _pages;
		}

		//=================================
		// protected properties 
		//=================================

		protected var _activePage : Label;

		protected var _activePageDelimiter : IVisualElement;

		protected var addLink : Boolean;

		//=================================
		// private properties 
		//=================================

		private var _selectedPage : IVisualElement;

		//=================================
		// public methods 
		//=================================

		public function addPage( value : uint ) : void
		{
			if( _pages.indexOf( value ) == -1 )
			{
				if( _pages.length > 0 )
					addElement( getDelimiter() );

				var pl : PageLink = new PageLink( value );
				pl.addEventListener( MouseEvent.CLICK , page_clickHandler );
				pl.setStyle( "color" , getStyle( "color" ) );
				addElement( pl );
				_pages.push( value );

				addActivePageIdentifier();

				dispatchEvent( new Event( "pagesChanged" ) );
			}
		}

		//=================================
		// protected methods 
		//=================================

		protected function activePage_clickHandler( event : MouseEvent ) : void
		{
			markSelected( _activePage );
			dispatchEvent( new PageLinkGroupEvent( PageLinkGroupEvent.ACTIVE_PAGE_SELECTED ) );
		}

		override protected function createChildren() : void
		{
			super.createChildren();

			switch( _direction )
			{
				case "horizontal":
					if( !( layout is HorizontalLayout ) )
						layout = new HorizontalLayout();
					break;

				case "vertical":
					if( !( layout is VerticalLayout ) )
						layout = new VerticalLayout();
					break;

			}
		}

		protected function markSelected( selectedPage : IVisualElement ) : void
		{
			_selectedPage = selectedPage;

			for( var i : uint = 0 ; i < numElements ; i++ )
			{
				var el : IVisualElement = getElementAt( i );

				if( !( el is PageLink ) && el != _activePage )
					continue;

				if( el == selectedPage )
				{
					var sc : * = getStyle( "selectedColor" );

					if( isNaN( sc ) )
						sc = 0xFFFFFF;
					el[ "setStyle" ]( "color" , sc );
				}
				else
					el[ "setStyle" ]( "color" , getStyle( "color" ) );
			}
		}

		override protected function measure() : void
		{
			if( _activePage )
			{
				//todo: change based on direction
				measuredHeight = _activePage.height;
			}
		}

		protected function page_clickHandler( event : MouseEvent ) : void
		{
			var pl : PageLink = event.currentTarget as PageLink;
			markSelected( pl );
			dispatchEvent( new PageLinkGroupEvent( PageLinkGroupEvent.PAGE_SELECTED , pl.page ) );
		}

		//=================================
		// private methods 
		//=================================

		private function addActivePageIdentifier() : void
		{
			if( !_activePage )
			{
				_activePage = new Label();
				_activePage.useHandCursor = true;
				_activePage.buttonMode = true;
				_activePage.addEventListener( MouseEvent.CLICK , activePage_clickHandler );
				_activePage.text = "[...]";
				_activePage.setStyle( "color" , getStyle( "color" ) );

				_activePageDelimiter = getDelimiter();
			}

			addElement( _activePageDelimiter )
			addElement( _activePage );

			if( !_selectedPage )
				markSelected( _activePage );
			validateNow();
		}

		private function getDelimiter() : IVisualElement
		{
			var l : Label = new Label();
			l.text = "|";
			l.setStyle( "color" , getStyle( "color" ) );
			return l;
		}
	}
}
