import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

extension MesureWidgetExtension on Widget {
  Size measureWidget({
    BoxConstraints constraints = const BoxConstraints(),
    MesureWidgetExtensionAncestors widgetAncestors =
        const MesureWidgetExtensionAncestors(),
  }) {
    final pipelineOwner = PipelineOwner();
    final rootView = pipelineOwner.rootNode = _MeasurementView(constraints);
    final buildOwner = BuildOwner(focusManager: FocusManager());
    final element = RenderObjectToWidgetAdapter<RenderBox>(
      container: rootView,
      debugShortDescription: '[root]',
      child: widgetAncestors._insertAncestors(this),
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

extension on MesureWidgetExtensionAncestors {
  Widget _insertAncestors(Widget widget) {
    var updatedWidget = widget;
    if (directionality != null) {
      updatedWidget = Directionality(
        textDirection: directionality!,
        child: widget,
      );
    }
    return updatedWidget;
  }
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
