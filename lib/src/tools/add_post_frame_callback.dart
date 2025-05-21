import 'package:flutter/material.dart';

void addPostFrameCallback(void Function() callback) =>
    WidgetsBinding.instance.addPostFrameCallback((_) => callback());
