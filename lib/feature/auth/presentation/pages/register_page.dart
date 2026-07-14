import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/register_controller.dart';
import '../providers/auth_providers.dart';
import '../providers/register_state.dart';
import 'package:Softbee/core/router/app_routes.dart'; // Importar AppRoutes
// Importar AppColors

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key}); // Añadir super.key

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class AppColors {
  static const Color primaryYellow = Color(0xFFFFD100);
  static const Color accentYellow = Color(0xFFFFAB00);
  static const Color lightYellow = Color(0xFFFFF8E1);
  static const Color darkYellow = Color(0xFFF9A825);
  static const Color textDark = Color(0xFF333333);
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  late final TextEditingController _nombreCtrl = TextEditingController();
  late final TextEditingController _correoCtrl = TextEditingController();
  late final TextEditingController _telefonoCtrl = TextEditingController();
  late final TextEditingController _passCtrl = TextEditingController();
  late final TextEditingController _confirmPassCtrl = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Suscribir los controladores de texto a los métodos del StateNotifier
    _nombreCtrl.addListener(
      () => ref
          .read(registerControllerProvider.notifier)
          .onNameChanged(_nombreCtrl.text),
    );
    _correoCtrl.addListener(
      () => ref
          .read(registerControllerProvider.notifier)
          .onEmailChanged(_correoCtrl.text),
    );
    _telefonoCtrl.addListener(
      () => ref
          .read(registerControllerProvider.notifier)
          .onPhoneChanged(_telefonoCtrl.text),
    );
    _passCtrl.addListener(
      () => ref
          .read(registerControllerProvider.notifier)
          .onPasswordChanged(_passCtrl.text),
    );
    _confirmPassCtrl.addListener(
      () => ref
          .read(registerControllerProvider.notifier)
          .onConfirmPasswordChanged(_confirmPassCtrl.text),
    );
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _correoCtrl.dispose();
    _telefonoCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    // La eliminación de apiarios se gestionará a través del controlador si es necesario
    super.dispose();
  }

  TextInputFormatter get _phoneFormatter {
    return TextInputFormatter.withFunction((oldValue, newValue) {
      String text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

      if (text.length <= 3) {
        return TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      } else if (text.length <= 6) {
        text = '${text.substring(0, 3)} ${text.substring(3)}';
      } else if (text.length <= 10) {
        text =
            '${text.substring(0, 3)} ${text.substring(3, 6)} ${text.substring(6)}';
      } else {
        text = text.substring(0, 10);
        text =
            '${text.substring(0, 3)} ${text.substring(3, 6)} ${text.substring(6)}';
      }

      return TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    });
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 60,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '¡Registro Exitoso!',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textDark.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Colors.green, Color(0xFF4CAF50)],
                  ),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    GoRouter.of(
                      context,
                    ).go(AppRoutes.dashboardRoute); // Redirigir al dashboard
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: Text(
                    'Continuar',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 60,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Error en el Registro',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textDark.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Colors.red, Color(0xFFE53935)],
                  ),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: Text(
                    'Intentar de nuevo',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? togglePasswordVisibility,
    TextInputType keyboardType = TextInputType.text,
    String? errorText,
    Function(String)? onChanged,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: isPassword && !isPasswordVisible,
            keyboardType: keyboardType,
            style: const TextStyle(color: AppColors.textDark),
            inputFormatters: inputFormatters,
            onChanged: onChanged,
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              labelStyle: TextStyle(
                color: errorText != null ? Colors.red : AppColors.darkYellow,
              ),
              prefixIcon: Icon(
                icon,
                color: errorText != null ? Colors.red : AppColors.primaryYellow,
              ),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        isPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: errorText != null
                            ? Colors.red
                            : AppColors.primaryYellow,
                      ),
                      onPressed: togglePasswordVisibility,
                    )
                  : (errorText != null
                        ? const Icon(Icons.error_outline, color: Colors.red)
                        : (controller.text.isNotEmpty && errorText == null
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                )
                              : null)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: errorText != null
                      ? Colors.red.withOpacity(0.5)
                      : AppColors.primaryYellow.withOpacity(0.3),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: errorText != null
                      ? Colors.red
                      : AppColors.primaryYellow,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errorText,
                    style: GoogleFonts.poppins(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (errorText == null && controller.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Campo válido',
                  style: GoogleFonts.poppins(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFooter(double width, double fontSize) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Text(
          '© ${DateTime.now().year} SoftBee. Todos los derechos reservados.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: AppColors.textDark.withOpacity(0.6),
            fontSize: fontSize * 0.7,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Escuchar cambios de estado del RegisterController
    ref.listen<RegisterState>(registerControllerProvider, (previous, next) {
      if (next.isRegistered) {
        _showSuccessDialog(
          '¡Bienvenido! Tu cuenta ha sido creada exitosamente.',
        );
        ref
            .read(registerControllerProvider.notifier)
            .resetState(); // Limpiar el estado del formulario
      } else if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        _showErrorDialog(next.errorMessage!);
      }
    });

    final registerState = ref.watch(registerControllerProvider);
    final registerController = ref.read(registerControllerProvider.notifier);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final isSmallScreen = width < 600;
          final isLandscape = width > height;
          final isDesktop = width > 1024;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.lightYellow, Colors.white],
              ),
            ),
            child: SafeArea(
              child: isDesktop
                  ? _buildDesktopLayout(
                      context,
                      width,
                      height,
                      registerState,
                      registerController,
                    )
                  : (isLandscape && isSmallScreen
                        ? _buildLandscapeLayout(
                            context,
                            width,
                            height,
                            registerState,
                            registerController,
                          )
                        : _buildPortraitLayout(
                            context,
                            width,
                            height,
                            isSmallScreen,
                            registerState,
                            registerController,
                          )),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    double width,
    double height,
    RegisterState registerState,
    RegisterController registerController,
  ) {
    final logoSize = width * 0.12;
    final titleSize = width * 0.025;
    final subtitleSize = width * 0.015;
    final verticalSpacing = height * 0.025;

    return Row(
      children: [
        Container(
          width: width * 0.4,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.lightYellow, Colors.white.withOpacity(0.9)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(5, 0),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(seconds: 1),
                  builder: (context, value, child) {
                    return Transform.scale(scale: value, child: child);
                  },
                  child: Container(
                    height: logoSize,
                    width: logoSize,
                    decoration: BoxDecoration(
                      color: AppColors.primaryYellow,
                      borderRadius: BorderRadius.circular(logoSize * 0.3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.darkYellow.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.hive,
                      size: logoSize * 0.4,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: verticalSpacing),
                Text(
                  'SoftBee',
                  style: GoogleFonts.poppins(
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: verticalSpacing * 0.5),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.02,
                    vertical: height * 0.015,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.lightYellow,
                    borderRadius: BorderRadius.circular(height * 0.02),
                    border: Border.all(
                      color: AppColors.primaryYellow,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    'Crea tu cuenta de apicultor',
                    style: GoogleFonts.poppins(
                      fontSize: subtitleSize,
                      color: AppColors.darkYellow,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: width * 0.05,
                vertical: height * 0.05,
              ),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Registro',
                          style: GoogleFonts.poppins(
                            fontSize: titleSize * 0.9,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: verticalSpacing),
                        _buildRegistrationStepper(
                          width,
                          height,
                          subtitleSize,
                          registerState,
                          registerController,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    double width,
    double height,
    bool isSmallScreen,
    RegisterState registerState,
    RegisterController registerController,
  ) {
    final logoSize = width * (isSmallScreen ? 0.25 : 0.10);
    final titleSize = width * (isSmallScreen ? 0.05 : 0.02);
    final subtitleSize = width * (isSmallScreen ? 0.04 : 0.03);
    final verticalSpacing = height * 0.02;

    return Column(
      children: [
        // Header fijo
        Container(
          height: height * 0.2, // Reducido para dar más espacio al contenido
          padding: EdgeInsets.all(width * 0.05),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(seconds: 1),
                  builder: (context, value, child) {
                    return Transform.scale(scale: value, child: child);
                  },
                  child: Container(
                    height: logoSize,
                    width: logoSize,
                    decoration: BoxDecoration(
                      color: AppColors.primaryYellow,
                      borderRadius: BorderRadius.circular(logoSize * 0.3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.darkYellow.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.hive,
                      size: logoSize * 0.4,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: verticalSpacing * 0.5),
                Text(
                  'Registro SoftBee',
                  style: GoogleFonts.poppins(
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: width * 0.05),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildRegistrationStepper(
                    width,
                    height,
                    subtitleSize,
                    registerState,
                    registerController,
                  ),
                  SizedBox(height: verticalSpacing),
                  _buildFooter(width, subtitleSize),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    double width,
    double height,
    RegisterState registerState,
    RegisterController registerController,
  ) {
    final logoSize = height * 0.25;
    final titleSize = height * 0.06;
    final subtitleSize = height * 0.035;
    final horizontalPadding = width * 0.05;
    final verticalSpacing = height * 0.03;

    return Row(
      children: [
        // Logo lateral fijo
        Container(
          width: width * 0.3,
          padding: EdgeInsets.all(horizontalPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: logoSize,
                width: logoSize,
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow,
                  borderRadius: BorderRadius.circular(logoSize * 0.25),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.darkYellow.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.hive,
                  size: logoSize * 0.4,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: verticalSpacing * 0.5),
              Text(
                'SoftBee',
                style: GoogleFonts.poppins(
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        // Contenido scrolleable
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(horizontalPadding),
            child: Form(
              key: _formKey,
              child: _buildRegistrationStepper(
                width,
                height,
                subtitleSize,
                registerState,
                registerController,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegistrationStepper(
    double width,
    double height,
    double fontSize,
    RegisterState registerState,
    RegisterController registerController,
  ) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
          primary: AppColors.primaryYellow,
          secondary: AppColors.accentYellow,
        ),
      ),
      child: Stepper(
        type: StepperType.vertical,
        currentStep: registerState.currentStep,
        physics: const NeverScrollableScrollPhysics(),
        onStepContinue: () {
          final isLastStep = registerState.currentStep == 1;

          if (isLastStep) {
            registerController.submitRegistration();
          } else {
            registerController.incrementStep();
          }
        },
        onStepCancel: () {
          if (registerState.currentStep > 0) {
            registerController.decrementStep();
          } else {
            Navigator.of(context).pop();
          }
        },
        onStepTapped: (step) {
          registerController.goToStep(step);
        },
        controlsBuilder: (context, details) {
          final isLastStep = registerState.currentStep == 1;

          return Container(
            margin: const EdgeInsets.only(top: 20, bottom: 20),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryYellow.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.primaryYellow,
                          AppColors.accentYellow,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: registerState.isLoading
                          ? null
                          : details.onStepContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: registerState.isLoading && isLastStep
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isLastStep
                                      ? Icons.check_circle
                                      : Icons.navigate_next,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  isLastStep ? 'Registrarse' : 'Continuar',
                                  style: GoogleFonts.poppins(
                                    fontSize: fontSize,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: registerState.isLoading
                        ? null
                        : details.onStepCancel,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: AppColors.primaryYellow,
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      registerState.currentStep > 0 ? 'Atrás' : 'Cancelar',
                      style: GoogleFonts.poppins(
                        color: AppColors.darkYellow,
                        fontWeight: FontWeight.normal,
                        fontSize: fontSize,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: Text(
              'Información Personal',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            content: Column(
              children: [
                _buildTextField(
                  controller: _nombreCtrl,
                  label: 'Nombre completo',
                  hint: 'Ingresa tu nombre',
                  icon: Icons.person_outline,
                  errorText: registerState.showValidationErrors
                      ? registerController.validateName(registerState.name)
                      : null,
                  onChanged: registerController.onNameChanged,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _correoCtrl,
                  label: 'Correo electrónico',
                  hint: 'ejemplo@correo.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  errorText: registerState.showValidationErrors
                      ? registerController.validateEmail(registerState.email)
                      : null,
                  onChanged: registerController.onEmailChanged,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _telefonoCtrl,
                  label: 'Teléfono',
                  hint: '3XX XXX XXXX',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _phoneFormatter,
                  ],
                  errorText: registerState.showValidationErrors
                      ? registerController.validatePhone(registerState.phone)
                      : null,
                  onChanged: registerController.onPhoneChanged,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _passCtrl,
                  label: 'Contraseña',
                  hint: 'Crea una contraseña segura',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  isPasswordVisible: registerState.isPasswordVisible,
                  togglePasswordVisibility:
                      registerController.togglePasswordVisibility,
                  errorText: registerState.showValidationErrors
                      ? registerController.validatePassword(
                          registerState.password,
                        )
                      : null,
                  onChanged: registerController.onPasswordChanged,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _confirmPassCtrl,
                  label: 'Confirmar contraseña',
                  hint: 'Repite tu contraseña',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  isPasswordVisible: registerState.isPasswordVisible,
                  togglePasswordVisibility:
                      registerController.togglePasswordVisibility,
                  errorText: registerState.showValidationErrors
                      ? registerController.validateConfirmPassword(
                          registerState.confirmPassword,
                        )
                      : null,
                  onChanged: registerController.onConfirmPasswordChanged,
                ),
                const SizedBox(height: 24),
                _buildPasswordRequirements(
                  registerState.password,
                  registerController,
                ),
              ],
            ),
            isActive: registerState.currentStep >= 0,
            state: registerState.currentStep > 0
                ? StepState.complete
                : StepState.indexed,
          ),
          Step(
            title: Text(
              'Información de Apiarios',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            content: Column(
              children: [
                Text(
                  'Agrega información sobre tus apiarios',
                  style: GoogleFonts.poppins(
                    fontSize: fontSize,
                    color: AppColors.textDark.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 16),
                ...registerState.apiaries.asMap().entries.map((entry) {
                  final index = entry.key;
                  final apiary = entry.value;

                  return _buildApiaryCard(
                    apiary: apiary,
                    index: index,
                    onRemove: () => registerController.removeApiary(index),
                    showRemoveButton: registerState.apiaries.length > 1,
                    onNameChanged: (value) =>
                        registerController.updateApiaryName(index, value),
                    onAddressChanged: (value) =>
                        registerController.updateApiaryAddress(index, value),
                    showValidationErrors: registerState.showValidationErrors,
                  );
                }),
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 20),
                  child: OutlinedButton.icon(
                    onPressed: registerController.addApiary,
                    icon: const Icon(Icons.add, color: AppColors.darkYellow),
                    label: Text(
                      'Agregar otro apiario',
                      style: GoogleFonts.poppins(
                        color: AppColors.darkYellow,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: AppColors.primaryYellow,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            isActive: registerState.currentStep >= 1,
            state: registerState.currentStep > 1
                ? StepState.complete
                : StepState.indexed,
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordRequirements(
    String password,
    RegisterController controller,
  ) {
    final bool hasMinLength = controller.hasMinLength(password);
    final bool hasUppercase = controller.hasUppercase(password);
    final bool hasLowercase = controller.hasLowercase(password);
    final bool hasDigit = controller.hasDigit(password);
    final bool hasSpecialChar = controller.hasSpecialChar(password);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tu contraseña debe contener:',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 8),
        _buildRequirementRow('Mínimo 8 caracteres', hasMinLength),
        _buildRequirementRow('Al menos una mayúscula (A-Z)', hasUppercase),
        _buildRequirementRow('Al menos una minúscula (a-z)', hasLowercase),
        _buildRequirementRow('Al menos un número (0-9)', hasDigit),
        _buildRequirementRow(
          'Al menos un carácter especial (@\$!%*?&)',
          hasSpecialChar,
        ),
      ],
    );
  }

  Widget _buildRequirementRow(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle_outline : Icons.info_outline,
            color: isMet ? Colors.green : Colors.grey,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: isMet ? Colors.green.shade700 : Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiaryCard({
    required RegisterApiaryData apiary,
    required int index,
    required VoidCallback onRemove,
    required bool showRemoveButton,
    required Function(String) onNameChanged,
    required Function(String) onAddressChanged,
    required bool showValidationErrors,
  }) {
    return ApiaryCard(
      apiary: apiary,
      index: index,
      onRemove: onRemove,
      showRemoveButton: showRemoveButton,
      onNameChanged: onNameChanged,
      onAddressChanged: onAddressChanged,
      showValidationErrors: showValidationErrors,
    );
  }
}

class ApiaryCard extends ConsumerStatefulWidget {
  final RegisterApiaryData apiary;
  final int index;
  final VoidCallback onRemove;
  final bool showRemoveButton;
  final Function(String) onNameChanged;
  final Function(String) onAddressChanged;
  final bool showValidationErrors;

  const ApiaryCard({
    super.key,
    required this.apiary,
    required this.index,
    required this.onRemove,
    required this.showRemoveButton,
    required this.onNameChanged,
    required this.onAddressChanged,
    required this.showValidationErrors,
  });

  @override
  ConsumerState<ApiaryCard> createState() => _ApiaryCardState();
}

class _ApiaryCardState extends ConsumerState<ApiaryCard> {
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.apiary.name);
    _addressController = TextEditingController(text: widget.apiary.address);

    _nameController.addListener(() {
      if (_nameController.text != widget.apiary.name) {
        widget.onNameChanged(_nameController.text);
      }
    });
    _addressController.addListener(() {
      if (_addressController.text != widget.apiary.address) {
        widget.onAddressChanged(_addressController.text);
      }
    });
  }

  @override
  void didUpdateWidget(covariant ApiaryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.apiary.name != oldWidget.apiary.name &&
        _nameController.text != widget.apiary.name) {
      _nameController.text = widget.apiary.name;
    }
    if (widget.apiary.address != oldWidget.apiary.address &&
        _addressController.text != widget.apiary.address) {
      _addressController.text = widget.apiary.address;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryYellow.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.lightYellow,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Apiario ${widget.index + 1}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkYellow,
                  ),
                ),
                if (widget.showRemoveButton)
                  IconButton(
                    onPressed: widget.onRemove,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                    tooltip: 'Eliminar apiario',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildTextField(
                  controller: _nameController,
                  label: 'Nombre del apiario',
                  hint: 'Ej: Apiario Las Flores',
                  icon: Icons.label_outline,
                  errorText:
                      widget.showValidationErrors && widget.apiary.name.isEmpty
                      ? 'Por favor ingresa el nombre del apiario'
                      : (widget.showValidationErrors &&
                                widget.apiary.name.length < 3
                            ? 'El nombre debe tener al menos 3 caracteres'
                            : null),
                  onChanged: (value) {
                    /* Handled by listener */
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _addressController,
                  label: 'Dirección exacta del apiario',
                  hint: 'Ej: Cota, Vereda El Rosal - Finca La Esperanza',
                  icon: Icons.location_on_outlined,
                  errorText:
                      widget.showValidationErrors &&
                          widget.apiary.address.isEmpty
                      ? 'La dirección es requerida'
                      : null,
                  onChanged: (value) {
                    /* Handled by listener */
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? togglePasswordVisibility,
    TextInputType keyboardType = TextInputType.text,
    String? errorText,
    Function(String)? onChanged,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: isPassword && !isPasswordVisible,
            keyboardType: keyboardType,
            style: const TextStyle(color: AppColors.textDark),
            inputFormatters: inputFormatters,
            onChanged: onChanged,
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              labelStyle: TextStyle(
                color: errorText != null ? Colors.red : AppColors.darkYellow,
              ),
              prefixIcon: Icon(
                icon,
                color: errorText != null ? Colors.red : AppColors.primaryYellow,
              ),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        isPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: errorText != null
                            ? Colors.red
                            : AppColors.primaryYellow,
                      ),
                      onPressed: togglePasswordVisibility,
                    )
                  : (errorText != null
                        ? const Icon(Icons.error_outline, color: Colors.red)
                        : (controller.text.isNotEmpty && errorText == null
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                )
                              : null)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: errorText != null
                      ? Colors.red.withOpacity(0.5)
                      : AppColors.primaryYellow.withOpacity(0.3),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: errorText != null
                      ? Colors.red
                      : AppColors.primaryYellow,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errorText,
                    style: GoogleFonts.poppins(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (errorText == null && controller.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Campo válido',
                  style: GoogleFonts.poppins(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
