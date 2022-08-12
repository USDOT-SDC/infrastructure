#!/bin/bash

# Set up the config file and uncomment the line below
# to read sensitive vars
# . ~/log4sdc-env.sh

APIG_MODULE=module.utilities.module.log4sdc.module.apig

##################
# log4sdc.apig


#terraform import ${APIG_MODULE}.aws_ssm_parameter.log4sdc_api_id /log4sdc/API_ID
#terraform import ${APIG_MODULE}.aws_sqs_queue.log4sdc_sqs https://sqs.us-east-1.amazonaws.com/${AWS_ACCOUNT_NUM}/log4sdc-sqs
#terraform import ${APIG_MODULE}.aws_lambda_event_source_mapping.log4sdc_sqs_lambda ${Log4SdcSqsLambdaMappingUid}

#terraform import ${APIG_MODULE}.aws_iam_role.api log4sdc-api-gateway-role
#terraform import ${APIG_MODULE}.aws_iam_policy.api arn:aws:iam::${AWS_ACCOUNT_NUM}:policy/log4sdc-api-gateway-policy
#terraform import ${APIG_MODULE}.aws_iam_role_policy_attachment.api log4sdc-api-gateway-role/arn:aws:iam::${AWS_ACCOUNT_NUM}:policy/log4sdc-api-gateway-policy

#terraform import ${APIG_MODULE}.aws_api_gateway_rest_api.log4sdc-api ${Log4SdcApigId}
#terraform import ${APIG_MODULE}.aws_api_gateway_resource.HealthCheck ${Log4SdcApigId}/${Log4SdcApigResourceHealthCheckId}
#terraform import ${APIG_MODULE}.aws_api_gateway_method.HealthCheckGet ${Log4SdcApigId}/${Log4SdcApigResourceHealthCheckId}/GET
#terraform import ${APIG_MODULE}.aws_api_gateway_integration.HealthCheckIntegration ${Log4SdcApigId}/${Log4SdcApigResourceHealthCheckId}/GET
#terraform import ${APIG_MODULE}.aws_api_gateway_method_response.HealthCheckMethodResponse ${Log4SdcApigId}/${Log4SdcApigResourceHealthCheckId}/GET/200
#terraform import ${APIG_MODULE}.aws_api_gateway_integration_response.HealthCheckIntegrationResponse ${Log4SdcApigId}/${Log4SdcApigResourceHealthCheckId}/GET/200 

#terraform import ${APIG_MODULE}.aws_api_gateway_stage.log4sdc-api-stage ${Log4SdcApigId}/log4sdc-api

#terraform import ${APIG_MODULE}.aws_api_gateway_resource.Enqueue ${Log4SdcApigId}/${Log4SdcApigResourceEnqueueId}
#terraform import ${APIG_MODULE}.aws_api_gateway_method.EnqueueMethod ${Log4SdcApigId}/${Log4SdcApigResourceEnqueueId}/POST 
#terraform import ${APIG_MODULE}.aws_api_gateway_integration.EnqueueIntegration ${Log4SdcApigId}/${Log4SdcApigResourceEnqueueId}/POST
#terraform import ${APIG_MODULE}.aws_api_gateway_method_response.EnqueueMethodResponse ${Log4SdcApigId}/${Log4SdcApigResourceEnqueueId}/POST/200 
#terraform import ${APIG_MODULE}.aws_api_gateway_integration_response.EnqueueIntegrationResponse ${Log4SdcApigId}/${Log4SdcApigResourceEnqueueId}/POST/200


