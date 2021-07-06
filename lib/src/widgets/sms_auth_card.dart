part of auth_card;

class _SMSAuthCard extends StatefulWidget {
  _SMSAuthCard(
      {Key? key,
      required this.userValidator,
      required this.passwordValidator,
      required this.onSwitchLogin,
      required this.userType,
      required this.onSmsAuth,
      required this.sendSmsAuthCode,
      this.updatePassword})
      : super(key: key);

  final FormFieldValidator<String>? userValidator;
  final FormFieldValidator<String>? passwordValidator;
  final Function onSwitchLogin;
  final LoginUserType userType;
  final Future<String?>? Function(String) onSmsAuth;
  final Future<String?>? Function(String) sendSmsAuthCode;
  final Function(String)? updatePassword;

  @override
  _SMSAuthCardState createState() => _SMSAuthCardState();
}

class _SMSAuthCardState extends State<_SMSAuthCard>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formRecoverKey = GlobalKey();
  TextEditingController? _idController = TextEditingController();
  TextEditingController? _codeController = TextEditingController();
  TextEditingController? _passController = TextEditingController();
  TextEditingController? _confirmPassController = TextEditingController();
  final _idFocusNode = FocusNode();
  final _codeFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  var _isLoading = false;
  var _isSubmitting = false;
  AnimationController? _submitController;
  int _step = 0; // 0:id, 1:code, 2:password

  @override
  void initState() {
    super.initState();

    final auth = Provider.of<Auth>(context, listen: false);
    _idController!.text = auth.email;
    _submitController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _submitController!.dispose();
    super.dispose();
  }

  Future<bool> _submit() async {
    if (!_formRecoverKey.currentState!.validate()) {
      return false;
    }
    final auth = Provider.of<Auth>(context, listen: false);
    final messages = Provider.of<LoginMessages>(context, listen: false);

    _formRecoverKey.currentState!.save();
    await _submitController!.forward();
    setState(() => _isSubmitting = true);
    if (_step == 0) // send code
    {
      final error = await widget.sendSmsAuthCode(_idController!.text);
      if (error != null) {
        showErrorToast(context, messages.flushbarTitleError, error);
        setState(() => _isSubmitting = false);
        await _submitController!.reverse();
      } else {
        setState(() => _isSubmitting = false);
        await _submitController!.reverse();
        setState(() {
          _step = 1;
        });
      }
    } else if (_step == 1) // code check
    {
      final error = await widget.onSmsAuth(_codeController!.text);
      if (error != null) {
        showErrorToast(context, messages.flushbarTitleError, error);
        setState(() => _isSubmitting = false);
        await _submitController!.reverse();
        return false;
      } else {
        setState(() => _isSubmitting = false);
        await _submitController!.reverse();
        setState(() {
          _step = 2;
        });
      }
    } else if (_step == 2) // update password
    {
      if (widget.updatePassword != null) {
        await widget.updatePassword!(auth.password);
        showSuccessToast(
            context, messages.flushbarTitleSuccess, messages.smsAuthSuccess);
        setState(() => _isSubmitting = false);
        await _submitController!.reverse();
        _codeController!.text = '';
        _passController!.text = '';
        _confirmPassController!.text = '';
        _step = 0;
        widget.onSwitchLogin();
      }
    }
    return true;
  }

  Widget _buildUserField(
    double width,
    LoginMessages messages,
    Auth auth,
  ) {
    return AnimatedTextFormField(
      controller: _idController,
      width: width,
      labelText: messages.userHint,
      autofillHints: [TextFieldUtils.getAutofillHints(widget.userType)],
      prefixIcon: Icon(FontAwesomeIcons.solidUserCircle),
      keyboardType: TextFieldUtils.getKeyboardType(widget.userType),
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (value) {
        _submit();
      },
      validator: widget.userValidator,
      onSaved: (value) => auth.email = value!,
    );
  }

  Widget _buildSMSCodeField(double width, LoginMessages messages, Auth auth) {
    return AnimatedTextFormField(
      controller: _codeController,
      width: width,
      labelText: messages.smsAuthCodeHint,
      prefixIcon: Icon(FontAwesomeIcons.sms),
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (value) => _submit(),
    );
  }

  Widget _buildSendCodeButton(ThemeData theme, LoginMessages messages) {
    return AnimatedButton(
      controller: _submitController,
      text: messages.smsAuthSendCodeButton,
      onPressed: !_isSubmitting ? _submit : null,
    );
  }

  Widget _buildAuthenticationButton(ThemeData theme, LoginMessages messages) {
    return AnimatedButton(
      controller: _submitController,
      text: messages.smsAuthButton,
      onPressed: !_isSubmitting ? _submit : null,
    );
  }

  Widget _buildUpdatePasswordButton(ThemeData theme, LoginMessages messages) {
    return AnimatedButton(
      controller: _submitController,
      text: messages.updatePasswordButton,
      onPressed: !_isSubmitting ? _submit : null,
    );
  }

  Widget _buildBackButton(ThemeData theme, LoginMessages messages) {
    return MaterialButton(
      onPressed: !_isSubmitting
          ? () {
              _formRecoverKey.currentState!.save();
              widget.onSwitchLogin();
            }
          : null,
      padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textColor: theme.primaryColor,
      child: Text(messages.goBackButton),
    );
  }

  Widget _buildPasswordField(double width, LoginMessages messages, Auth auth) {
    return AnimatedPasswordTextFormField(
      animatedWidth: width,
      labelText: messages.passwordHint,
      autofillHints: [AutofillHints.newPassword],
      controller: _passController,
      textInputAction: TextInputAction.next,
      focusNode: _passwordFocusNode,
      onFieldSubmitted: (value) {
        if (auth.isLogin) {
          _submit();
        } else {
          // SignUp
          FocusScope.of(context).requestFocus(_confirmPasswordFocusNode);
        }
      },
      onSaved: (value) => auth.password = value!,
      validator: widget.passwordValidator,
    );
  }

  Widget _buildConfirmPasswordField(
      double width, LoginMessages messages, Auth auth) {
    return AnimatedPasswordTextFormField(
      animatedWidth: width,
      enabled: true,
      labelText: messages.confirmPasswordHint,
      controller: _confirmPassController,
      textInputAction: TextInputAction.done,
      focusNode: _confirmPasswordFocusNode,
      onFieldSubmitted: (value) {
        _submit();
      },
      validator: (value) {
        if (value != _passController!.text) {
          return messages.confirmPasswordError;
        }
        return null;
      },
      onSaved: (value) => auth.confirmPassword = value!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = Provider.of<Auth>(context, listen: false);
    final messages = Provider.of<LoginMessages>(context, listen: false);
    final deviceSize = MediaQuery.of(context).size;
    final cardWidth = min(deviceSize.width * 0.75, 360.0);
    const cardPadding = 16.0;
    final textFieldWidth = cardWidth - cardPadding * 2;

    return FittedBox(
      // width: cardWidth,
      child: Card(
        child: Container(
          padding: const EdgeInsets.only(
            left: cardPadding,
            top: cardPadding + 10.0,
            right: cardPadding,
            bottom: cardPadding,
          ),
          width: cardWidth,
          alignment: Alignment.center,
          child: Form(
            key: _formRecoverKey,
            child: Column(
              children: [
                if (_step == 0) _buildUserField(textFieldWidth, messages, auth),
                if (_step == 0) SizedBox(height: 26),
                if (_step == 0) _buildSendCodeButton(theme, messages),
                if (_step == 1)
                  Text(
                    messages.smsAuthCodeSended,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyText2,
                  ),
                if (_step == 1) SizedBox(height: 20),
                if (_step == 1)
                  _buildSMSCodeField(textFieldWidth, messages, auth),
                if (_step == 1) SizedBox(height: 26),
                if (_step == 1) _buildAuthenticationButton(theme, messages),
                if (_step == 2)
                  Text(
                    messages.smsAuthNewPassword,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyText2,
                  ),
                if (_step == 2) SizedBox(height: 20),
                if (_step == 2)
                  _buildPasswordField(textFieldWidth, messages, auth),
                if (_step == 2) SizedBox(height: 20),
                if (_step == 2)
                  _buildConfirmPasswordField(textFieldWidth, messages, auth),
                if (_step == 2) SizedBox(height: 26),
                if (_step == 2) _buildUpdatePasswordButton(theme, messages),
                _buildBackButton(theme, messages),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
