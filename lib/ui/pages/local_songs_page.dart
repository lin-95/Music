import 'dart:io';
import 'package:flutter/material.dart';
import '../widgets/liquid_glass_ui.dart';
import '../design_tokens.dart';
import '../adaptive_layout.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/player_controller.dart';
import '../../controllers/local_music_controller.dart';
import '../../core/folder_filter.dart';
import '../../models/music_models.dart';
import '../widgets/toast.dart';
import '../widgets/artwork.dart';
import '../widgets/mini_player.dart';
import '../widgets/now_playing_badge.dart';
import '../widgets/status_bar_overlay.dart';

class LocalSongsPage extends StatefulWidget {
