import logging
import os
import boto3
import json
import requests
import traceback
from requests_aws4auth import AWS4Auth
from common.constants import *

import time


region = 'us-east-1'
service = 'execute-api'
credentials = boto3.Session().get_credentials()
awsauth = AWS4Auth(credentials.access_key, credentials.secret_key, region, service, session_token=credentials.token)


class LoggerUtility:
    @staticmethod
    def get_param(ssm_client, key, default_value=None):
        if key in os.environ.keys():
            res = os.environ[key]
        else:
            try:
                res = ssm_client.get_parameter(Name='/log4sdc/' + key)['Parameter']['Value']
            except:
                res = default_value
        return res


    @staticmethod
    def init(project='SDC Platform',
             team='',
             sdc_service='',
             component=Constants.LOGGER_NAME,
             config=None):
        LoggerUtility.setLevel(project=project,
            team=team,
            sdc_service=sdc_service,
            component=component,
            config=config)
            

    @staticmethod
    def setLevel(project='SDC Platform',
             team='',
             sdc_service='',
             component=Constants.LOGGER_NAME,
             config=None):
        if not config:
            config = {}

        if not 'project' in config:
            config['project'] = project
        if not 'team' in config:
            config['team'] = team
        if not 'sdc_service' in config:
            config['sdc_service'] = sdc_service
        if not 'component' in config:
            config['component'] = component

        ssm = boto3.client('ssm', region_name='us-east-1')
        config['TOPIC_ARN_ERROR'] = LoggerUtility.get_param(ssm_client=ssm, key='TOPIC_ARN_ERROR')
        config['TOPIC_ARN_CRITICAL'] = LoggerUtility.get_param(ssm_client=ssm, key='TOPIC_ARN_CRITICAL')
        config['TOPIC_ARN_ALERT'] = LoggerUtility.get_param(ssm_client=ssm, key='TOPIC_ARN_ALERT')
        config['LOG_LEVEL'] = LoggerUtility.get_param(ssm_client=ssm, key='LOG_LEVEL', default_value=Constants.LOGGER_DEFAULT_LOG_LEVEL)
        api_id = LoggerUtility.get_param(ssm_client=ssm, key='API_ID', default_value='set_api_id')
        config['API_ENDPOINT_URL'] = f'https://{api_id}.execute-api.us-east-1.amazonaws.com/log4sdc-api/enqueue'

        LoggerUtility.config = config
        LoggerUtility.setLevelExec(level=config['LOG_LEVEL'])


    @staticmethod
    def setLevelExec(level=Constants.LOGGER_DEFAULT_LOG_LEVEL):
        logFormat = '%(asctime)-15s %(levelname)s:%(message)s'
        logging.basicConfig(format=logFormat)
        logger = logging.getLogger(Constants.LOGGER_NAME)

        try:
            logLevel = os.environ[Constants.LOGGER_LOG_LEVEL_ENV_VAR]
        except Exception as e:
            #logLevel = Constants.LOGGER_DEFAULT_LOG_LEVEL
            print(e)
            logLevel = level

        try:
            logger.setLevel(logging.getLevelName(logLevel))
        except Exception as e:
            print(e)
            logLevel = Constants.LOGGER_DEFAULT_LOG_LEVEL

        return True


    @staticmethod
    def logToApi(message, level, userdata=''):
        config = LoggerUtility.config
        
        msg = {}
        msg['level'] = level
        if 'project' in config:
            msg['project'] = config['project']
        if 'team' in config:
            msg['team'] = config['team']
        if 'component' in config:
            msg['component'] = config['component']
        msg['summary'] = message
        msg['userdata'] = userdata

        headers = { "Content-Type": "application/json" }
        
        try:
            res = requests.post(config['API_ENDPOINT_URL'], auth=awsauth, headers=headers, data=json.dumps(msg))
        except Exception as e:
            traceback.print_exc()
            return False
        
        #print(res)
        #print(res.status_code)
        #print(json.loads(res.text))

        return True


    @staticmethod
    def logDebug(message, subject=Constants.LOGGER_NAME + ' DEBUG', userdata=''):
        logger = logging.getLogger(Constants.LOGGER_NAME)
        logger.debug('%s', message)
        LoggerUtility.logToApi(message, level='DEBUG', userdata=userdata)
        return True


    @staticmethod
    def logInfo(message, subject=Constants.LOGGER_NAME + ' INFO', userdata=''):
        logger = logging.getLogger(Constants.LOGGER_NAME)
        logger.info('%s', message)
        LoggerUtility.logToApi(message, level='INFO', userdata=userdata)
        return True


    @staticmethod
    def logWarning(message, subject=Constants.LOGGER_NAME + ' WARNING', userdata=''):
        logger = logging.getLogger(Constants.LOGGER_NAME)
        logger.warning('%s', message)
        LoggerUtility.logToApi(message, level='WARNING', userdata=userdata)
        return True


    @staticmethod
    def logError(message, subject=Constants.LOGGER_NAME + ' ERROR', userdata=''):
        logger = logging.getLogger(Constants.LOGGER_NAME)
        logger.error('%s', message)
        client = boto3.client('sns', region_name='us-east-1')
        if hasattr(LoggerUtility, 'config') and LoggerUtility.config['TOPIC_ARN_ERROR']:
            response = client.publish(TopicArn=LoggerUtility.config['TOPIC_ARN_ERROR'], Subject=subject, Message=message)
        LoggerUtility.logToApi(message, level='ERROR', userdata=userdata)
        return True


    @staticmethod
    def logCritical(message, subject=Constants.LOGGER_NAME + ' CRITICAL', userdata=''):
        logger = logging.getLogger(Constants.LOGGER_NAME)
        logger.critical('%s', message)
        client = boto3.client('sns', region_name='us-east-1')
        if hasattr(LoggerUtility, 'config') and LoggerUtility.config['TOPIC_ARN_CRITICAL']:
            response = client.publish(TopicArn=LoggerUtility.config['TOPIC_ARN_CRITICAL'], Subject=subject, Message=message)
        LoggerUtility.logToApi(message, level='CRITICAL', userdata=userdata)
        return True


    @staticmethod
    def alert(message, subject=Constants.LOGGER_NAME + ' ALERT', userdata=''):
        logger = logging.getLogger(Constants.LOGGER_NAME)
        logger.error('%s', message)
        client = boto3.client('sns', region_name='us-east-1')
        if hasattr(LoggerUtility, 'config') and LoggerUtility.config['TOPIC_ARN_ALERT']:
            response = client.publish(TopicArn=LoggerUtility.config['TOPIC_ARN_ALERT'], Subject=subject, Message=message)
        LoggerUtility.logToApi(message, level='ALERT', userdata=userdata)
        return True


