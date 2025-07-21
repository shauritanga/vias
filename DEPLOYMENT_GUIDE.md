# VIAS Deployment Guide

## 🎯 **Two Separate Applications**

The VIAS project consists of **two distinct applications** designed for different user groups:

### 📱 **Mobile App (For Visually Impaired End Users)**
- **Entry Point**: `lib/main.dart`
- **Target Users**: Visually impaired students
- **Platform**: iOS and Android mobile devices
- **Features**: Voice commands, TTS, accessibility-first design
- **NO ADMIN FEATURES**: Pure end-user experience

### 🖥️ **Web Admin Portal (For DIT Administrators)**
- **Entry Point**: `lib/admin_main.dart`
- **Target Users**: DIT administrators and staff
- **Platform**: Web browsers (desktop/tablet)
- **Features**: PDF upload, user management, analytics
- **Admin Credentials**: username: `admin`, password: `dit2024`

## 🚀 **Deployment Instructions**

### **Mobile App Deployment**

#### **For Android (Google Play Store)**
```bash
# Build for Android
flutter build apk --release

# Or build App Bundle for Play Store
flutter build appbundle --release
```

#### **For iOS (Apple App Store)**
```bash
# Build for iOS
flutter build ios --release
```

### **Web Admin Portal Deployment**

#### **Build Web Admin Portal**
```bash
# Build web version using admin entry point
flutter build web --web-renderer html --dart-define=FLUTTER_WEB_USE_SKIA=false --target=lib/admin_main.dart
```

#### **Deploy to Web Hosting**
1. Upload the `build/web` folder to your web server
2. Configure your web server to serve the files
3. Set up HTTPS for security
4. Configure domain (e.g., `admin.vias.dit.ac.tz`)

## 🔧 **Configuration**

### **Firebase Configuration**
Both apps use the same Firebase project but with different configurations:

```dart
// Mobile app (main.dart) - End user features only
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

// Admin portal (admin_main.dart) - Admin features only
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

### **Environment Variables**
Create different environment configurations:

```bash
# For mobile app
FLUTTER_APP_TYPE=mobile
FLUTTER_TARGET_USERS=end_users

# For admin portal
FLUTTER_APP_TYPE=admin
FLUTTER_TARGET_USERS=administrators
```

## 📋 **Feature Separation**

### **Mobile App Features (End Users Only)**
✅ **Voice Commands**
- "Explore Programs"
- "View Fees" 
- "Admissions Info"
- "Ask Questions"
- "Stop" / "Repeat"

✅ **Accessibility Features**
- Text-to-speech with customizable settings
- High contrast design
- Large touch targets (60dp minimum)
- Screen reader compatibility
- Voice-guided navigation

✅ **Content Access**
- Read prospectus content via voice
- Search and browse programs
- Access fee information
- Get admission requirements

❌ **NO Admin Features**
- No PDF upload
- No user management
- No analytics dashboard
- No admin controls

### **Web Admin Portal Features (Administrators Only)**
✅ **Content Management**
- PDF upload and processing
- Content categorization
- Content editing and updates

✅ **User Management**
- View registered users
- Monitor user activity
- Manage user preferences
- Handle support requests

✅ **Analytics & Monitoring**
- Usage statistics
- Performance metrics
- System health monitoring
- User engagement analytics

✅ **System Administration**
- Admin authentication
- System configuration
- Data backup and restore

## 🔐 **Security Considerations**

### **Mobile App Security**
- No admin credentials stored
- Read-only access to content
- User data encryption
- Secure API communication

### **Admin Portal Security**
- Admin authentication required
- Role-based access control
- Secure file upload handling
- Activity logging and monitoring

## 📱 **User Experience Design**

### **Mobile App (Accessibility-First)**
- **Voice-First Interface**: Primary interaction through voice commands
- **Large Text**: Minimum 18sp font size
- **High Contrast**: WCAG AA compliant color schemes
- **Touch Targets**: Minimum 60dp for easy access
- **Screen Reader**: Full TalkBack/VoiceOver support
- **Simple Navigation**: Linear, predictable navigation flow

### **Admin Portal (Efficiency-First)**
- **Visual Interface**: Rich visual dashboard
- **Data Visualization**: Charts and graphs for analytics
- **Bulk Operations**: Efficient content management
- **Multi-tab Interface**: Organized feature access
- **Responsive Design**: Works on desktop and tablet

## 🧪 **Testing Strategy**

### **Mobile App Testing**
```bash
# Run mobile app tests
flutter test

# Test with screen readers
# - Enable TalkBack (Android) or VoiceOver (iOS)
# - Test all voice commands
# - Verify accessibility features
```

### **Admin Portal Testing**
```bash
# Run admin portal tests
flutter test --target=lib/admin_main.dart

# Test admin features
# - PDF upload functionality
# - User management features
# - Analytics dashboard
```

## 📊 **Monitoring & Analytics**

### **Mobile App Monitoring**
- User engagement metrics
- Voice command usage
- Accessibility feature usage
- App performance metrics

### **Admin Portal Monitoring**
- Admin login activity
- Content upload frequency
- System performance
- User support metrics

## 🔄 **Update Strategy**

### **Mobile App Updates**
- Regular accessibility improvements
- Voice recognition enhancements
- Content updates via API
- Bug fixes and performance improvements

### **Admin Portal Updates**
- New admin features
- Enhanced analytics
- Security updates
- UI/UX improvements

## 📞 **Support & Maintenance**

### **End User Support**
- Voice-guided help system
- Audio tutorials
- Accessibility support hotline
- Email support for technical issues

### **Admin Support**
- Admin documentation
- Training materials
- Technical support
- System maintenance guides

## 🎯 **Success Metrics**

### **Mobile App Success**
- User adoption rate among visually impaired students
- Voice command accuracy and usage
- Accessibility compliance score
- User satisfaction ratings

### **Admin Portal Success**
- Content upload efficiency
- Admin user adoption
- System uptime and performance
- Support request resolution time

---

**Remember**: Keep the mobile app and admin portal completely separate to maintain focus on their respective user groups and use cases!
