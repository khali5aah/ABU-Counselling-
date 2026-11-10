from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("registrations", "0002_studentregistration_has_consented"),
    ]

    operations = [
        migrations.AddField(
            model_name="studentregistration",
            name="signup_code_hash",
            field=models.CharField(blank=True, max_length=64),
        ),
        migrations.AddField(
            model_name="studentregistration",
            name="signup_code_expires_at",
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name="studentregistration",
            name="signup_code_used_at",
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name="studentregistration",
            name="signup_code_attempts",
            field=models.PositiveSmallIntegerField(default=0),
        ),
    ]
