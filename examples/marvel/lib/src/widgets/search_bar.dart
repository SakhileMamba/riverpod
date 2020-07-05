import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:marvel/src/screens/character_detail.dart';
import 'package:marvel/src/screens/home.dart';

class _SearchTheme {
  const _SearchTheme({
    this.width,
    this.searchDecoration,
    this.iconPadding,
    this.searchMargin,
  });

  final double width;
  final BoxDecoration searchDecoration;
  final EdgeInsets iconPadding;
  final EdgeInsets searchMargin;
}

const _kFocusedTheme = _SearchTheme(
  width: 210,
  searchDecoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.all(Radius.circular(10)),
  ),
  iconPadding: EdgeInsets.only(right: 8),
  searchMargin: EdgeInsets.only(right: 10),
);

const _kUnfocusedTheme = _SearchTheme(
  width: 40,
  searchDecoration: BoxDecoration(
    color: Colors.transparent,
    borderRadius: BorderRadius.all(Radius.circular(10)),
  ),
  iconPadding: EdgeInsets.zero,
  searchMargin: EdgeInsets.zero,
);

class SearchBar extends HookWidget {
  const SearchBar({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    /// Whether the widget is focused or not determines if the widget
    /// is currently "searching" or in idle state.
    final searchFocusNode = useFocusNode();
    useListenable(searchFocusNode);
    final theme = searchFocusNode.hasFocus ? _kFocusedTheme : _kUnfocusedTheme;

    final textFocusNode = useFocusNode();
    final textEditingController = useTextEditingController(text: 'Iron man');

    return Focus(
      focusNode: searchFocusNode,
      child: _SearchbarView(
        theme: theme,
        isFocused: searchFocusNode.hasFocus,
        textEditingController: textEditingController,
        textFocusNode: textFocusNode,
        // TODO move PortalEntry above _SearchbarView after fixing constraint issue on flutter_portal
        bottom: PortalEntry(
          visible: searchFocusNode.hasFocus,
          childAnchor: Alignment.bottomCenter,
          portalAnchor: Alignment.topCenter,
          portal: _SearchHintContainer(
            theme: theme,
            child: _SearchHints(textEditingController: textEditingController),
          ),
          child: Container(),
        ),
      ),
    );
  }
}

class _SearchHints extends HookWidget {
  _SearchHints({
    Key key,
    @required this.textEditingController,
  }) : super(key: key);

  final TextEditingController textEditingController;

  @override
  Widget build(BuildContext context) {
    final filter = useValueListenable(textEditingController).text;
    print(filter);

    return useProvider(charactersCount(filter)).when(
      loading: () => const Center(
        heightFactor: 1,
        child: Padding(
          padding: EdgeInsets.all(8),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, stack) => const Center(
        heightFactor: 1,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text('Error'),
        ),
      ),
      data: (count) {
        return ListView.separated(
          shrinkWrap: true,
          itemCount: count,
          separatorBuilder: (context, _) => const Divider(height: 0),
          itemBuilder: (context, index) {
            return HookBuilder(
              builder: (context) {
                final character = useProvider(characterAtIndex(
                  CharacterOffset(offset: index, name: filter),
                ));

                return character.when(
                  loading: () {
                    return const Center(child: CircularProgressIndicator());
                  },
                  error: (err, stack) => const Center(child: Text('Error')),
                  data: (character) {
                    return ListTile(
                      visualDensity: VisualDensity.compact,
                      onTap: () {},
                      title: Text(
                        character.name,
                        style: Theme.of(context).textTheme.bodyText2,
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _SearchHintContainer extends StatelessWidget {
  const _SearchHintContainer({
    Key key,
    @required this.theme,
    @required this.child,
  }) : super(key: key);

  final _SearchTheme theme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 150),
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: Container(
        constraints: BoxConstraints(
          minWidth: theme.width,
          maxWidth: theme.width,
          maxHeight: 300,
        ),
        margin: theme.searchMargin,
        child: Material(
          elevation: 16,
          borderRadius: theme.searchDecoration.borderRadius,
          clipBehavior: Clip.hardEdge,
          child: child,
        ),
      ),
    );
  }
}

class _SearchbarView extends StatelessWidget {
  const _SearchbarView({
    Key key,
    @required this.theme,
    @required this.isFocused,
    @required this.textEditingController,
    @required this.textFocusNode,
    @required this.bottom,
  }) : super(key: key);

  final _SearchTheme theme;
  final bool isFocused;
  final TextEditingController textEditingController;
  final FocusNode textFocusNode;
  final Widget bottom;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        GestureDetector(
          // Don't unfocus when tapping the searchbar
          behavior: HitTestBehavior.opaque,
          onTap: () {},
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: theme.width,
            height: 35,
            margin: theme.searchMargin,
            decoration: theme.searchDecoration,
          ),
        ),
        Positioned.fill(
          left: 12,
          right: 50,
          child: ExcludeSemantics(
            excluding: !isFocused,
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextField(
                controller: textEditingController,
                focusNode: textFocusNode,
                onTap: () {},
                scrollController: ScrollController(),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Iron man',
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(child: bottom),
        AnimatedTheme(
          data: isFocused //
              ? ThemeData.light()
              : ThemeData.dark(),
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 150),
            padding: theme.iconPadding,
            child: IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Search by name',
              onPressed: textFocusNode.requestFocus,
            ),
          ),
        ),
      ],
    );
  }
}
