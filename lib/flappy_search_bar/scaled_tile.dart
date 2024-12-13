import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

/// Class only use in order to give access to StaggeredTile to users
class ScaledTile extends StaggeredGridTile {
  /// Creates a [ScaledTile] with the given [crossAxisCellCount] that
  /// fit its main axis extent to its content.
  ///
  /// This tile will have a fixed main axis extent.
  const ScaledTile.fit(int crossAxisCellCount, Widget child, {super.key})
      : super.fit(crossAxisCellCount: crossAxisCellCount, child: child);

  /// Creates a [ScaledTile] with the given [crossAxisCellCount] and
  /// [mainAxisExtent].
  ///
  /// This tile will have a fixed main axis extent.
  const ScaledTile.extent(int crossAxisCellCount, double mainAxisExtent, Widget child, {super.key})
      : super.extent(crossAxisCellCount: crossAxisCellCount, mainAxisExtent: mainAxisExtent, child: child);

  /// Creates a [ScaledTile] with the given [crossAxisCellCount] and
  /// [mainAxisCellCount].
  ///
  /// The main axis extent of this tile will be the length of
  /// [mainAxisCellCount] cells (inner spacings included).
  const ScaledTile.count(
    int crossAxisCellCount,
    num mainAxisCellCount,
    Widget child, {super.key}
  ) : super.count(crossAxisCellCount: crossAxisCellCount, mainAxisCellCount: mainAxisCellCount, child: child);
}
