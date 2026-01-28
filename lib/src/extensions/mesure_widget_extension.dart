import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

extension MesureWidgetExtension on Widget {
  Size measureWidget({
    BoxConstraints constraints = const BoxConstraints(),
    MediaQueryData? mediaQueryData,
  }) {
    final pipelineOwner = PipelineOwner();
    final rootView = pipelineOwner.rootNode = _MeasurementView(constraints);
    final buildOwner = BuildOwner(focusManager: FocusManager());

    final wrappedWidget = MediaQuery(
      data:
          mediaQueryData ??
          MediaQueryData.fromView(
            WidgetsBinding.instance.platformDispatcher.views.first,
          ),
      child: Directionality(textDirection: TextDirection.ltr, child: this),
    );

    final element = RenderObjectToWidgetAdapter<RenderBox>(
      container: rootView,
      debugShortDescription: '[root]',
      child: wrappedWidget,
    ).attachToRenderTree(buildOwner);
    try {
      rootView.scheduleInitialLayout();
      pipelineOwner.flushLayout();
      return rootView.size;
    } finally {
      element.update(
        RenderObjectToWidgetAdapter<RenderBox>(container: rootView),
      );
      buildOwner.finalizeTree();
    }
  }
}

class MesureWidgetExtensionAncestors {
  const MesureWidgetExtensionAncestors({
    this.directionality = TextDirection.ltr,
  });
  final TextDirection? directionality;
}

class _MeasurementView extends RenderBox
    with RenderObjectWithChildMixin<RenderBox> {
  _MeasurementView(this.boxConstraints);
  final BoxConstraints boxConstraints;

  @override
  void performLayout() {
    child!.layout(boxConstraints, parentUsesSize: true);
    size = child!.size;
  }

  @override
  void debugAssertDoesMeetConstraints() => true;
}
