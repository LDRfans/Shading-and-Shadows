#pragma once

#include "GL/glew.h"
#include <string>

class GLShader
{
public:
	GLShader(void);
	~GLShader(void);

	void LoadShaderProgramFromFile(const char *filename);
	void DeleteShader();
	GLuint GetShader() {return m_shader;}

private:
	GLuint m_shader;

	GLuint CompileShader(GLenum type, const GLchar *pszSource, GLint length);
	GLuint LinkShaders(GLuint vertShader, GLuint geomShader, GLuint fragShader);
	void ReadTextFileToBuffer(const char *filename, std::string &buffer);
};
