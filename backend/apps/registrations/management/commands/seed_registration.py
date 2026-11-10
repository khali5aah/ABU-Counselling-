from django.core.management.base import BaseCommand, CommandError

from apps.registrations.serializers import RegistrationCreateSerializer


class Command(BaseCommand):
    help = "Create a student registration record from command-line input."

    def add_arguments(self, parser):
        parser.add_argument("--first-name", dest="first_name", required=True)
        parser.add_argument("--last-name", dest="last_name", required=True)
        parser.add_argument("--matric", dest="matric_number", required=True)
        parser.add_argument("--phone", dest="phone_number", required=True)

    def handle(self, *args, **options):
        serializer = RegistrationCreateSerializer(
            data={
                "first_name": options["first_name"],
                "last_name": options["last_name"],
                "matric_number": options["matric_number"],
                "phone_number": options["phone_number"],
            }
        )
        try:
            serializer.is_valid(raise_exception=True)
            registration = serializer.save()
        except Exception as exc:  # pragma: no cover - surfaced to CLI users
            raise CommandError(str(exc)) from exc

        self.stdout.write(
            self.style.SUCCESS(
                f"Created registration for {registration.first_name} {registration.last_name} "
                f"({registration.matric_number})"
            )
        )
