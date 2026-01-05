import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/di/service_locator.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/location/presentation/bloc/location_bloc.dart';
import '../features/location/presentation/widgets/location_card.dart';
import '../features/steps/data/steps_repository_impl.dart';
import '../features/steps/presentation/bloc/steps_bloc.dart';
import '../features/steps/presentation/widgets/steps_card.dart';

class FitnessApp extends StatelessWidget {
  const FitnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc(sl())),
        BlocProvider(create: (_) => LocationBloc(sl(), sl())),
        BlocProvider(
          create: (_) => StepsBloc(
            startSensors: sl(),
            stopSensors: sl(),
            metricsStream: sl.get<StepsRepositoryImpl>().metricsStream(),
            notifications: sl(),
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Fitness Tracker',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6366F1)),
          useMaterial3: true,
        ),
        home: const _AuthWrapper(),
      ),
    );
  }
}

class _AuthWrapper extends StatefulWidget {
  const _AuthWrapper();

  @override
  State<_AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<_AuthWrapper> {
  bool _isAuthed = false;

  void _onAuthed() => setState(() => _isAuthed = true);

  @override
  Widget build(BuildContext context) {
    if (!_isAuthed) return LoginPage(onAuthenticated: _onAuthed);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fitness Tracker'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            StepsCard(),
            SizedBox(height: 16),
            LocationCard(),
          ],
        ),
      ),
    );
  }
}
