import os
import json
import socket
import sys
import boto3

# Get Environment varilables
vCluster = os.environ.get('Cluster_EndPoint')
vELB_arn = os.environ.get('NLB_TG_ARN')
vNewPort = os.environ.get('RDS_Port')
client = boto3.client('elbv2')

def lambda_handler(event, context):

    # DeRegister old IP from NLB
    def deregister_oldip(vOldIp, vOldPort, vOldAZ):
        response = client.deregister_targets(
            TargetGroupArn=vELB_arn,
            Targets=[
                {
                    'Id': vOldIp,
                    'Port': vOldPort,
                    'AvailabilityZone': vOldAZ
                },
            ]
        )

# Register new IP to NLB
    def register_newip(vNewIP, vNewPort):
        response = client.register_targets(
            TargetGroupArn=vELB_arn,
            Targets=[
                {
                    'Id': vNewIP,
                    'Port': int(vNewPort)
                },
            ]
        )

# Get Master Node IP address
    vNewIP = socket.gethostbyname_ex(vCluster)    
    IPs = vNewIP[2]
    print('IP list from DNS: ', IPs)

# Get Registered IP detail from NLB        
    dictNLB = client.describe_target_health(
        TargetGroupArn=vELB_arn
    )

    ip_list = []
    for i in  dictNLB['TargetHealthDescriptions']:
        ip = i.get('Target').get('Id')
        ip_list.append(ip)

    if not ip_list:
        for nIP in IPs:
            print('Register New IP ', nIP, 'Port: ', vNewPort)
            register_newip(nIP, vNewPort)

    DeRegisterIP = set(ip_list) - set(IPs)
    RegisterIP = set(IPs) - set(ip_list)
    
    if DeRegisterIP:
        print('IP: ', str(DeRegisterIP), ' will be DeRegistered from NLB Target')
    
    if RegisterIP:
        print('IP: ', str(RegisterIP), ' will be registered to NLB Target')

    for nIP in RegisterIP:
        print('Registering New IP ', nIP, 'Port: ', vNewPort)
        register_newip(nIP, vNewPort)
        
    for oIP in dictNLB['TargetHealthDescriptions']:
        vOldIp = oIP.get('Target').get('Id')
        vOldPort = oIP.get('Target').get('Port')
        vOldAZ = oIP.get('Target').get('AvailabilityZone')
        print('IP list from NLB Target Group: ', vOldIp)
        if vOldIp in DeRegisterIP:
            print('DeRegister IP: ', vOldIp, 'Port; ', vOldPort, 'AZ: ', vOldAZ)
            deregister_oldip(vOldIp, vOldPort, vOldAZ)
