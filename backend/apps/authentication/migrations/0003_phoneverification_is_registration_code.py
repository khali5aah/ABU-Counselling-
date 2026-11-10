from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("authentication", "0002_phoneverification"),
        ("registrations", "0003_signup_code"),
    ]

    operations = [
        migrations.AddField(
            model_name="phoneverification",
            name="is_registration_code",
            field=models.BooleanField(default=False),
        ),
    ]
