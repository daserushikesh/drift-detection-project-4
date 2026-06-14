import boto3
import json
import logging
import os
from datetime import datetime

# Setup logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# AWS Clients
ec2_client = boto3.client('ec2')
logs_client = boto3.client('logs')

# Configuration - these match your Terraform state
CORRECT_CONFIG = {
    'ec2_tags': {
        'Environment': 'Production',
        'ManagedBy': 'Terraform'
    },
    'sg_allowed_ingress': [
        {
            'port': 22,
            'protocol': 'tcp',
            'cidr': '10.0.0.0/8',
            'description': 'Allow SSH'
        },
        {
            'port': 80,
            'protocol': 'tcp',
            'cidr': '10.0.0.0/8',
            'description': 'Allow HTTP'
        }
    ]
}

# Read from environment variables
EC2_INSTANCE_ID = os.environ.get('EC2_INSTANCE_ID')
SECURITY_GROUP_ID = os.environ.get('SECURITY_GROUP_ID')
LOG_GROUP_NAME = os.environ.get('LOG_GROUP_NAME', '/drift-detection/remediation')


def log_event(message, event_type="INFO"):
    """Log events to CloudWatch"""
    timestamp = datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S UTC')
    log_message = {
        "timestamp": timestamp,
        "event_type": event_type,
        "message": message
    }
    logger.info(json.dumps(log_message))
    return log_message


def remediate_ec2_tags(instance_id):
    """Restore correct EC2 tags"""
    try:
        log_event(f"Checking EC2 tags for instance: {instance_id}")

        # Get current tags
        response = ec2_client.describe_instances(InstanceIds=[instance_id])
        current_tags = response['Reservations'][0]['Instances'][0].get('Tags', [])
        current_tag_dict = {tag['Key']: tag['Value'] for tag in current_tags}

        log_event(f"Current tags: {current_tag_dict}")

        # Check for drift
        drift_detected = False
        tags_to_fix = []

        for key, correct_value in CORRECT_CONFIG['ec2_tags'].items():
            current_value = current_tag_dict.get(key)
            if current_value != correct_value:
                drift_detected = True
                tags_to_fix.append({
                    'key': key,
                    'current': current_value,
                    'correct': correct_value
                })
                log_event(
                    f"DRIFT DETECTED - Tag '{key}': '{current_value}' should be '{correct_value}'",
                    "DRIFT"
                )

        # Check for unauthorized tags
        unauthorized_tags = []
        authorized_keys = list(CORRECT_CONFIG['ec2_tags'].keys()) + ['Name']
        for key in current_tag_dict:
            if key not in authorized_keys:
                unauthorized_tags.append(key)
                drift_detected = True
                log_event(
                    f"DRIFT DETECTED - Unauthorized tag found: '{key}'",
                    "DRIFT"
                )

        if drift_detected:
            # Remove unauthorized tags
            if unauthorized_tags:
                ec2_client.delete_tags(
                    Resources=[instance_id],
                    Tags=[{'Key': k} for k in unauthorized_tags]
                )
                log_event(f"Removed unauthorized tags: {unauthorized_tags}", "REMEDIATED")

            # Restore correct tags
            correct_tags = [
                {'Key': k, 'Value': v}
                for k, v in CORRECT_CONFIG['ec2_tags'].items()
            ]
            ec2_client.create_tags(
                Resources=[instance_id],
                Tags=correct_tags
            )
            log_event(f"EC2 tags restored to correct state", "REMEDIATED")
            return {"status": "REMEDIATED", "resource": "EC2_TAGS", "changes": tags_to_fix}
        else:
            log_event("EC2 tags are compliant - no action needed", "COMPLIANT")
            return {"status": "COMPLIANT", "resource": "EC2_TAGS"}

    except Exception as e:
        log_event(f"Error remediating EC2 tags: {str(e)}", "ERROR")
        raise


def remediate_security_group(sg_id):
    """Restore correct security group rules"""
    try:
        log_event(f"Checking Security Group: {sg_id}")

        # Get current SG rules
        response = ec2_client.describe_security_groups(GroupIds=[sg_id])
        sg = response['SecurityGroups'][0]
        current_ingress = sg.get('IpPermissions', [])

        log_event(f"Current ingress rules count: {len(current_ingress)}")

        # Define correct ingress rules
        correct_ingress = [
            {
                'IpProtocol': 'tcp',
                'FromPort': rule['port'],
                'ToPort': rule['port'],
                'IpRanges': [{'CidrIp': rule['cidr'], 'Description': rule['description']}]
            }
            for rule in CORRECT_CONFIG['sg_allowed_ingress']
        ]

        # Check if current rules match correct rules
        drift_detected = False

        # Check for extra/wrong rules
        for rule in current_ingress:
            from_port = rule.get('FromPort', 0)
            for ip_range in rule.get('IpRanges', []):
                cidr = ip_range.get('CidrIp', '')
                # Check if this is an unauthorized rule
                is_authorized = False
                for correct_rule in CORRECT_CONFIG['sg_allowed_ingress']:
                    if (from_port == correct_rule['port'] and
                            cidr == correct_rule['cidr']):
                        is_authorized = True
                        break
                if not is_authorized:
                    drift_detected = True
                    log_event(
                        f"DRIFT DETECTED - Unauthorized SG rule: Port {from_port} from {cidr}",
                        "DRIFT"
                    )

        if drift_detected:
            # Remove ALL current ingress rules
            if current_ingress:
                ec2_client.revoke_security_group_ingress(
                    GroupId=sg_id,
                    IpPermissions=current_ingress
                )
                log_event("Removed all existing ingress rules", "REMEDIATION")

            # Add back only the correct rules
            ec2_client.authorize_security_group_ingress(
                GroupId=sg_id,
                IpPermissions=correct_ingress
            )
            log_event("Security Group restored to correct state", "REMEDIATED")
            return {"status": "REMEDIATED", "resource": "SECURITY_GROUP"}
        else:
            log_event("Security Group is compliant - no action needed", "COMPLIANT")
            return {"status": "COMPLIANT", "resource": "SECURITY_GROUP"}

    except Exception as e:
        log_event(f"Error remediating Security Group: {str(e)}", "ERROR")
        raise


def lambda_handler(event, context):
    """Main Lambda handler"""
    log_event("=== Drift Detection & Remediation Started ===", "START")
    log_event(f"Triggered by event: {json.dumps(event)}")

    results = []

    try:
        # Remediate EC2 Tags
        if EC2_INSTANCE_ID:
            ec2_result = remediate_ec2_tags(EC2_INSTANCE_ID)
            results.append(ec2_result)
        else:
            log_event("EC2_INSTANCE_ID not set", "WARNING")

        # Remediate Security Group
        if SECURITY_GROUP_ID:
            sg_result = remediate_security_group(SECURITY_GROUP_ID)
            results.append(sg_result)
        else:
            log_event("SECURITY_GROUP_ID not set", "WARNING")

        # Summary
        remediated = [r for r in results if r['status'] == 'REMEDIATED']
        compliant = [r for r in results if r['status'] == 'COMPLIANT']

        summary = {
            "total_checks": len(results),
            "remediated": len(remediated),
            "compliant": len(compliant),
            "results": results
        }

        log_event(f"=== Remediation Complete: {json.dumps(summary)} ===", "COMPLETE")

        return {
            "statusCode": 200,
            "body": json.dumps(summary)
        }

    except Exception as e:
        log_event(f"Lambda execution failed: {str(e)}", "ERROR")
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }
