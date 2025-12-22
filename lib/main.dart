import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Importaciones de Auth
import 'features/auth/data/datasources/biometric_datasource.dart';
import 'features/auth/domain/usecases/authenticate_user.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/login_page.dart';

// Importación del Contador de Pasos
import 'features/steps/presentation/widgets/step_counter_widget.dart';

// Importación del Widget del Mapa GPS
import 'features/tracking/presentation/widgets/route_map_widget.dart';

void main() {
  runApp(const FitnessApp());
}

class FitnessApp extends StatelessWidget {
  const FitnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Inyección de Dependencias
    final biometricDataSource = BiometricDataSourceImpl();
    final authenticateUser = AuthenticateUser(biometricDataSource);

    return MaterialApp(
      title: 'Fitness Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6366F1)),
        useMaterial3: true,
      ),
      home: BlocProvider(
        create: (_) => AuthBloc(authenticateUser),
        child: const AuthWrapper(),
      ),
    );
  }
}

/// Widget que decide qué pantalla mostrar: Login o Home
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isAuthenticated = false;

  void _onAuthSuccess() {
    setState(() {
      _isAuthenticated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthenticated) {
      return const HomePage();
    }
    return LoginPage(onAuthSuccess: _onAuthSuccess);
  }
}

/// Pantalla Principal donde vivirá nuestro Fitness Tracker
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fitness Tracker'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // AQUÍ ESTÁ NUESTRO WIDGET DE PASOS
            StepCounterWidget(),

            SizedBox(height: 16),

            RouteMapWidget(),
            
            // Más tarde pondremos aquí el Mapa GPS...
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Aquí irá el mapa GPS pronto...'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
