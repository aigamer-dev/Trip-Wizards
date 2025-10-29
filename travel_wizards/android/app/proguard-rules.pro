## ProGuard rules generated from R8 missing rules
# Added to suppress warnings and keep necessary classes referenced by external libs

# R8 missing classes generated rules (from build/app/outputs/mapping/release/missing_rules.txt)
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivity$g
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Args
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Error
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningEphemeralKeyProvider

# You can add additional -keep rules here if R8 removes classes required at runtime
