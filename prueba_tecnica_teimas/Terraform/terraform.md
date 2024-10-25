# Terraform

## Automatizar el despliegue del servidor nginx indicado arriba mediante un script en terraform. Al realizar esta automatización debemos de reutilizar el servidor existente, no pudiendo haber interrupción del servicio.

Me he planteado el siguiente punto de la prueba técnica: como una importación de código creado a mano en AWS, y deseamos automatizar el control de esta infraestructura mediante el uso de Terraform.

He procedido a realizar la **IMPORTACIÓN** de todos los recursos creados en AWS siguiendo los siguientes pasos:

1. **Creación de un provider** cumpliendo las versiones necesarias para la infraestructura en cuestión.  

2. **Creación uno por uno de cada recurso (básico)**.

3. **Importar cada recurso mediante su ID específico** (ejemplo para la EC2):
   ```bash
   terraform import aws_instance.nginx i-0cb2d505126a225bc
   ```
    - Cualquier necesidad que tengamos sobre el servidor de NGINX la podremos implementar utilizando el provisioner `remote-exec`, al cual podremos adjuntar un script, ya sea inline o un `script.sh`, ya que el User data solo trabaja en el momento de la creación del servidor y no es lo que buscamos en este caso.
    - Una vez listo, ejecutaremos `terraform plan` y `terraform apply`; este último ejecutará el `remote-exec`.

4. **Comprobar**:   
   ```bash
   terraform state list
   ```

5. **Verificar el contenido exacto del recurso para implementarlo en mi recurso básico creado**:  
   ```bash
   terraform state show
   ```
   
6. **Upgrade version de NGINX**
    Podemos modificar el script de User Data para realizar cambios en la versión de NGINX, por ejemplo, usando el mismo servidor y sin necesidad de reiniciar el servidor.

7. **Terraform plan y apply**
    Esto nos actualizará solo los cambios específicos realizados.