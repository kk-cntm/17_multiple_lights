#version 330 core

#define NR_POINT_LIGHTS 4

struct DirLight {
    vec3 direction;
    
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
};

struct PointLight {
    vec3 position;
    
    float constant;
    float linear;
    float quadratic;
    
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
};

struct SpotLight {
    vec3 position;
    vec3 direction;
    
    float constant;
    float linear;
    float quadratic;
    
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
    
    float innerCone;
    float outerCone;
};

struct Material {
    sampler2D diffuse;
    sampler2D specular;
    float shininess;
};

vec3 CalcDirLight(DirLight light, vec3 normal, vec3 viewDir);
vec3 CalcPointLight(PointLight light, vec3 normal, vec3 fragPos, vec3 viewDir);
vec3 CalcSpotLight(SpotLight light, vec3 normal, vec3 fragPos, vec3 viewDir);

out vec4 FragColor;

in vec2 TexPos;
in vec3 FragPos;
in vec3 Normal;

uniform DirLight dirLight;
uniform PointLight pointLights[NR_POINT_LIGHTS];
uniform SpotLight spotLight;
uniform Material material;
uniform vec3 cameraPos;

void main() {
    vec3 normal = normalize(Normal);
    vec3 viewDir = normalize(FragPos - cameraPos);
    
    vec3 result = CalcDirLight(dirLight, normal, viewDir);
    
    for (int i = 0; i < NR_POINT_LIGHTS; i++) {
        result += CalcPointLight(pointLights[i], normal, FragPos, viewDir);
    }
    
    result += CalcSpotLight(spotLight, normal, FragPos, viewDir);
    
    FragColor = vec4(result, 1.0f);
}

vec3 CalcDirLight(DirLight light, vec3 normal, vec3 viewDir) {
    vec3 normLightDir = normalize(light.direction);
    vec3 ambient = light.ambient * texture(material.diffuse, TexPos).rgb;
    
    float cosAngle = max(dot(-normLightDir, normal), 0.0f);
    vec3 diffuse = light.diffuse * cosAngle * texture(material.diffuse, TexPos).rgb;
    
    vec3 lightReflection = reflect(normLightDir, normal);
    float spec = pow(max(dot(lightReflection, -viewDir), 0.0f), material.shininess);
    vec3 specular = light.specular * spec * texture(material.specular, TexPos).rgb;
    
    return ambient + diffuse + specular;
}

vec3 CalcPointLight(PointLight light, vec3 normal, vec3 fragPos, vec3 viewDir) {
    vec3 normLightDir = normalize(fragPos - light.position);
    vec3 ambient = light.ambient * texture(material.diffuse, TexPos).rgb;
    
    float cosAngle = max(dot(-normLightDir, normal), 0.0f);
    vec3 diffuse = light.diffuse * cosAngle * texture(material.diffuse, TexPos).rgb;
    
    vec3 lightReflection = reflect(normLightDir, normal);
    float spec = pow(max(dot(lightReflection, -viewDir), 0.0f), material.shininess);
    vec3 specular = light.specular * spec * texture(material.specular, TexPos).rgb;
    
    float distance = length(fragPos - light.position);
    float attenuation = 1.0f / (light.constant + light.linear * distance + light.quadratic * distance * distance);
    
    ambient *= attenuation; // TODO try to remove
    diffuse *= attenuation;
    specular *= attenuation;
    
    return ambient + diffuse + specular;
}

vec3 CalcSpotLight(SpotLight light, vec3 normal, vec3 fragPos, vec3 viewDir) {
    vec3 normLightFragDir = normalize(fragPos - light.position);
    vec3 normLightDir = normalize(light.direction);
    
    vec3 ambient = light.ambient * texture(material.diffuse, TexPos).rgb;
    
    float cosAngle = max(dot(-viewDir, normal), 0.0f);
    vec3 diffuse = light.diffuse * cosAngle * texture(material.diffuse, TexPos).rgb;
    
    vec3 lightReflection = reflect(normLightFragDir, normal);
    float spec = pow(max(dot(lightReflection, -viewDir), 0.0f), material.shininess);
    vec3 specular = light.specular * spec * texture(material.specular, TexPos).rgb;
    
    float distance = length(fragPos - light.position);
    float attenuation = 1.0f / (light.constant + light.linear * distance + light.quadratic * distance * distance);
    
    float theta = dot(normLightFragDir, normLightDir);
    float epsilon = light.innerCone - light.outerCone;
    float intensity = clamp((theta - light.outerCone) / epsilon, 0.0f, 1.0f);
    
    ambient *= attenuation * intensity;
    diffuse *= attenuation * intensity;
    specular *= attenuation * intensity;
    
    return ambient + diffuse + specular;
}
