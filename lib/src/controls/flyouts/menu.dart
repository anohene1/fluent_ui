import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';

/// Menu flyouts are used in menu and context menu scenarios to display a list
/// of commands or options when requested by the user. A menu flyout shows a
/// single, inline, top-level menu that can have menu items and sub-menus.
///
/// ![MenuFlyout](https://docs.microsoft.com/en-us/windows/apps/design/controls/images/contextmenu_rs2_icons.png)
///
/// See also:
///
///  * [FlyoutController], which displays a flyout to the given target
///  * <https://learn.microsoft.com/en-us/windows/apps/design/controls/menus>
class MenuFlyout extends StatefulWidget {
  /// Creates a menu flyout.
  const MenuFlyout({
    super.key,
    this.items = const [],
    this.color,
    this.shape,
    this.shadowColor = Colors.black,
    this.elevation = 8.0,
    this.constraints,
    this.padding = const EdgeInsets.only(top: 8.0),
  });

  /// {@template fluent_ui.flyouts.menu.items}
  /// The colletion used to generate the content of the menu.
  ///
  /// See also:
  ///
  ///  * [MenuFlyoutItem], a single item in the list of items
  ///  * [MenuFlyoutSeparator], which represents a horizontal line that
  ///    separates items in a [MenuFlyout].
  ///  * [MenuFlyoutSubItem], which represents a menu item that displays a
  ///    sub-menu in a [MenuFlyout]
  /// {@end-template}
  final List<MenuFlyoutItemBase> items;

  /// The background color of the box.
  final Color? color;

  /// The shape to fill the [color] of the box.
  final ShapeBorder? shape;

  /// The shadow color.
  final Color shadowColor;

  /// The z-coordinate relative to the box at which to place this physical
  /// object.
  final double elevation;

  /// Additional constraints to apply to the child.
  final BoxConstraints? constraints;

  /// The padding applied the [items], with correct handling when scrollable
  final EdgeInsetsGeometry? padding;

  static const EdgeInsetsGeometry itemsPadding = EdgeInsets.symmetric(
    horizontal: 8.0,
  );

  @override
  State<MenuFlyout> createState() => _MenuFlyoutState();
}

class _MenuFlyoutState extends State<MenuFlyout> {
  var keys = <GlobalKey>[];

  void generateKeys() {
    if (widget.items.whereType<MenuFlyoutSubItem>().isNotEmpty) {
      keys = widget.items.map((item) {
        if (item is MenuFlyoutSubItem) {
          return GlobalKey<_MenuFlyoutSubItemState>();
        }

        return GlobalKey();
      }).toList();
    }
  }

  @override
  void initState() {
    super.initState();
    generateKeys();
  }

  @override
  Widget build(BuildContext context) {
    final hasLeading = widget.items
        .whereType<MenuFlyoutItem>()
        .any((item) => item.leading != null);

    final menuInfo = MenuInfoProvider.of(context);

    Widget content = FlyoutContent(
      color: widget.color,
      constraints: widget.constraints,
      elevation: widget.elevation,
      shadowColor: widget.shadowColor,
      shape: widget.shape,
      padding: EdgeInsets.zero,
      child: ScrollConfiguration(
        behavior: const _MenuScrollBehavior(),
        child: SingleChildScrollView(
          padding: widget.padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: List.generate(widget.items.length, (index) {
              final item = widget.items[index];
              if (item is MenuFlyoutItem) item._useIconPlaceholder = hasLeading;
              if (item is MenuFlyoutSubItem && keys.isNotEmpty) {
                item._key = keys[index] as GlobalKey<_MenuFlyoutSubItemState>?;
              }
              return KeyedSubtree(
                key: item.key,
                child: item.build(context),
              );
            }),
          ),
        ),
      ),
    );

    if (keys.isNotEmpty) {
      content = MouseRegion(
        onHover: (event) {
          for (final subItem
              in keys.whereType<GlobalKey<_MenuFlyoutSubItemState>>()) {
            final state = subItem.currentState;
            if (state == null || subItem.currentContext == null) continue;
            if (!state.isShowing(menuInfo)) continue;

            final itemBox =
                subItem.currentContext!.findRenderObject() as RenderBox;
            final itemRect = itemBox.localToGlobal(Offset.zero) & itemBox.size;

            if (!itemRect.contains(event.position)) {
              state.close(menuInfo);
            }
          }
        },
        child: content,
      );
    }

    return content;
  }
}

// Do not use the platform-specific default scroll configuration.
// Menus should never overscroll or display an overscroll indicator.
class _MenuScrollBehavior extends FluentScrollBehavior {
  const _MenuScrollBehavior();

  @override
  TargetPlatform getPlatform(BuildContext context) => defaultTargetPlatform;

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics();
}

/// See also:
///
///  * [MenuFlyout], which displays a list of commands or options
///  * [MenuFlyoutItem], a single item in the list of items
///  * [MenuFlyoutSeparator], which represents a horizontal line that
///    separates items in a [MenuFlyout].
///  * [MenuFlyoutSubItem], which represents a menu item that displays a
///    sub-menu in a [MenuFlyout]
///  * [MenuFlyoutItemBuilder], which renders the given widget in the items list
abstract class MenuFlyoutItemBase {
  final Key? key;

  const MenuFlyoutItemBase({this.key});

  Widget build(BuildContext context);
}

/// Render any widget in the items list of a [MenuFlyout]
///
/// See also:
///
///  * [MenuFlyout], which displays a list of commands or options
///  * [MenuFlyoutItem], a single item in the list of items
///  * [MenuFlyoutSeparator], which represents a horizontal line that
///    separates items in a [MenuFlyout].
///  * [MenuFlyoutSubItem], which represents a menu item that displays a
///    sub-menu in a [MenuFlyout]
class MenuFlyoutItemBuilder extends MenuFlyoutItemBase {
  final WidgetBuilder builder;

  /// Creates a menu flyout item builder
  const MenuFlyoutItemBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) => builder(context);
}

/// The standard flyout item used inside a [MenuFlyout]
///
/// See also:
///
///  * [MenuFlyout], which displays a list of commands or options
///  * [MenuFlyoutSeparator], which represents a horizontal line that
///    separates items in a [MenuFlyout].
///  * [MenuFlyoutSubItem], which represents a menu item that displays a
///    sub-menu in a [MenuFlyout]
class MenuFlyoutItem extends MenuFlyoutItemBase {
  /// Creates a menu flyout item
  MenuFlyoutItem({
    super.key,
    this.leading,
    required this.text,
    this.trailing,
    required this.onPressed,
    this.selected = false,
  });

  /// Displayed before [text].
  ///
  /// Don't feel obligated to provide icons for commands that don't have a
  /// standard visualization. Cryptic icons aren't helpful, create visual
  /// clutter, and prevent users from focusing on the important menu items.
  ///
  /// ![](https://learn.microsoft.com/en-us/windows/apps/design/controls/images/contextmenu_rs2_icons.png)
  ///
  /// Usually an [Icon] widget,
  final Widget? leading;
  final Widget text;
  final Widget? trailing;
  final VoidCallback? onPressed;
  final bool selected;

  bool _useIconPlaceholder = false;

  @override
  Widget build(BuildContext context) {
    final size = Flyout.of(context).size;
    return Container(
      width: size.isEmpty ? null : size.width,
      padding: MenuFlyout.itemsPadding,
      child: FlyoutListTile(
        selected: selected,
        showSelectedIndicator: false,
        icon: leading ??
            () {
              if (_useIconPlaceholder) return const Icon(null);
              return null;
            }(),
        text: text,
        trailing: IconTheme.merge(
          data: const IconThemeData(size: 12.0),
          child: trailing ?? const SizedBox.shrink(),
        ),
        onPressed: onPressed,
      ),
    );
  }
}

/// Represents a horizontal line that separates items in a [MenuFlyout].
///
/// See also:
///
///  * [MenuFlyout], which displays a list of commands or options
///  * [MenuFlyoutItem], a single item in the list of items
///  * [MenuFlyoutSubItem], which represents a menu item that displays a
///    sub-menu in a [MenuFlyout]
class MenuFlyoutSeparator extends MenuFlyoutItemBase {
  /// Creates a menu flyout separator
  const MenuFlyoutSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    final size = Flyout.of(context).size;

    return SizedBox(
      width: size.width,
      child: const Padding(
        padding: EdgeInsetsDirectional.only(bottom: 5.0),
        child: Divider(
          style: DividerThemeData(horizontalMargin: EdgeInsets.zero),
        ),
      ),
    );
  }
}

enum SubItemShowBehavior {
  /// Whether the sub-menu will be shown on item press
  press,

  /// Whether the sub-menu will be shown on item hover
  ///
  /// This is the default behavior.
  hover,
}

typedef MenuItemsBuilder = List<MenuFlyoutItemBase> Function(
  BuildContext context,
);

/// Represents a menu item that displays a sub-menu in a [MenuFlyout].
///
/// ![](https://learn.microsoft.com/en-us/windows/apps/design/controls/images/menu-bar-submenu.png)
///
/// See also:
///
///  * [MenuFlyout], which displays a list of commands or options
///  * [MenuFlyoutItem], a single item in the list of items
///  * [MenuFlyoutSeparator], which represents a horizontal line that
///    separates items in a [MenuFlyout].
class MenuFlyoutSubItem extends MenuFlyoutItem {
  /// Creates a menu flyout sub item
  MenuFlyoutSubItem({
    super.key,
    super.leading,
    required super.text,
    super.trailing = const Icon(FluentIcons.chevron_right),
    required this.items,
    this.showBehavior = SubItemShowBehavior.hover,
    this.showHoverDelay = const Duration(milliseconds: 450),
  }) : super(onPressed: null);

  /// It is the key of `_MenuFlyoutSubItem`, built in the `build` method. It
  /// can not use the parent `key` widget because it's already used by
  /// `MenuFlyout` to build the widget. It is assigned by `MenuFlyout` with a
  /// key generated by `generateKeys()`. It is used to close the child menu when
  /// its parent is closed
  GlobalKey<_MenuFlyoutSubItemState>? _key;

  /// The colletion used to generate the content of the menu.
  ///
  /// {@macro fluent_ui.flyouts.menu.items}
  final MenuItemsBuilder items;

  /// Represent which user action will show the sub-menu.
  ///
  /// Defaults to [SubItemShowBehavior.hover]
  final SubItemShowBehavior showBehavior;

  /// The sub-menu will be only shown after this delay
  ///
  /// Only applied if [showBehavior] is [SubItemShowBehavior.hover]
  final Duration showHoverDelay;

  @override
  Widget build(BuildContext context) {
    return _MenuFlyoutSubItem(key: _key, item: this, items: items);
  }
}

class _MenuFlyoutSubItem extends StatefulWidget {
  final MenuFlyoutSubItem item;
  final MenuItemsBuilder items;

  const _MenuFlyoutSubItem({
    super.key,
    required this.item,
    required this.items,
  });

  @override
  State<_MenuFlyoutSubItem> createState() => _MenuFlyoutSubItemState();
}

class _MenuFlyoutSubItemState extends State<_MenuFlyoutSubItem>
    with SingleTickerProviderStateMixin {
  /// The animation controller responsible for the animation of the flyout
  ///
  /// The duration is defined at build time
  late final transitionController = AnimationController(vsync: this);

  final menuKey = GlobalKey<_MenuFlyoutState>();

  Timer? showTimer;

  @override
  void dispose() {
    transitionController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_MenuFlyoutSubItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    final parent = Flyout.of(context);
    if (transitionController.duration == null ||
        transitionController.duration != parent.transitionDuration) {
      transitionController.duration = parent.transitionDuration;
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuInfo = MenuInfoProvider.of(context);

    final item = MenuFlyoutItem(
      key: widget.item.key,
      text: widget.item.text,
      leading: widget.item.leading,
      selected: isShowing(menuInfo),
      trailing: widget.item.trailing,
      onPressed: () {
        show(menuInfo);
      },
    ).build(context);

    if (widget.item.showBehavior == SubItemShowBehavior.hover) {
      return MouseRegion(
        onEnter: (event) {
          showTimer = Timer(widget.item.showHoverDelay, () {
            show(menuInfo);
          });
        },
        onExit: (event) {
          if (showTimer != null && showTimer!.isActive) {
            showTimer!.cancel();
          }
        },
        child: item,
      );
    }

    return item;
  }

  bool isShowing(MenuInfoProviderState menuInfo) {
    return menuInfo.contains(menuKey);
  }

  void show(MenuInfoProviderState menuInfo) {
    final itemBox = context.findRenderObject() as RenderBox;
    final itemRect = itemBox.localToGlobal(Offset.zero) & itemBox.size;

    final parent = Flyout.of(context);

    menuInfo.add(
      CustomSingleChildLayout(
        delegate: _SubItemPositionDelegate(
          parentRect: itemRect,
          parentSize: itemBox.size,
          margin: parent.margin,
        ),
        child: Flyout(
          rootFlyout: parent.rootFlyout,
          menuKey: menuKey,
          additionalOffset: parent.additionalOffset,
          margin: parent.margin,
          transitionDuration: parent.transitionDuration,
          builder: (context) {
            return FadeTransition(
              opacity: transitionController,
              child: MenuFlyout(
                key: menuKey,
                items: widget.items(context),
              ),
            );
          },
        ),
      ),
      menuKey,
    );

    transitionController.forward();
    setState(() {});
  }

  /// Closes this menu and its children
  Future<void> close(MenuInfoProviderState menuInfo) async {
    await Future.wait([
      if (menuKey.currentState != null)
        ...menuKey.currentState!.keys
            .whereType<GlobalKey<_MenuFlyoutSubItemState>>()
            .map((child) => child.currentState!.close(menuInfo)),
      transitionController.reverse(),
    ]);

    menuInfo.remove(menuKey);

    if (mounted) setState(() {});
  }
}

class _SubItemPositionDelegate extends SingleChildLayoutDelegate {
  final Rect parentRect;
  final Size parentSize;
  final double margin;

  const _SubItemPositionDelegate({
    required this.parentRect,
    required this.parentSize,
    required this.margin,
  });

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return constraints.loosen();
  }

  @override
  Offset getPositionForChild(Size rootSize, Size flyoutSize) {
    var x = parentRect.left +
        parentRect.size.width -
        MenuFlyout.itemsPadding.horizontal / 2;

    // if the flyout will overflow the screen on the right
    final willOverflowX = x + flyoutSize.width + margin > rootSize.width;

    // if overflow x on the right, we check for some cases
    //
    // if the space available on the right is greater than the space available on
    // the left, use the right.
    //
    // otherwise, we position the flyout at the end of the screen
    if (willOverflowX) {
      final rightX = parentRect.left -
          flyoutSize.width +
          MenuFlyout.itemsPadding.horizontal / 2;
      if (rightX > margin) {
        x = rightX;
      } else {
        x = clampDouble(
          rootSize.width - flyoutSize.width - margin,
          0,
          rootSize.width,
        );
      }
    }

    var y = parentRect.top;
    final willOverflowY = y + flyoutSize.height + margin > rootSize.height;

    if (willOverflowY) {
      y = parentRect.top + parentRect.height - flyoutSize.height;
    }

    return Offset(x, y);
  }

  @override
  bool shouldRelayout(covariant SingleChildLayoutDelegate oldDelegate) {
    return true;
  }
}
