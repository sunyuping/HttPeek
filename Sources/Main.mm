
//
#import <vector>
#import <algorithm>

//
#if __cplusplus
extern "C"
#endif
const void *LogData(const void *data, size_t dataLength, void *returnAddress)
{
	if (data == nil || dataLength == 0)
		return data;

    _LogLine();
	static int s_index = 0;
	static NSString *_logDir = nil;
	static std::vector<NSURLRequest *> _requests;

	if (_logDir == nil)
	{
		_logDir = [[NSString alloc] initWithFormat:@"/tmp/%@.req", NSProcessInfo.processInfo.processName];
		[[NSFileManager defaultManager] createDirectoryAtPath:_logDir withIntermediateDirectories:YES attributes:nil error:nil];
	}

	Dl_info info = {0};
	dladdr(returnAddress, &info);

	NSString *str = [NSString stringWithFormat:@"FROM %s(%p)-%s(%p=>%#08lx)\n<%@>\n\n", info.dli_fname, info.dli_fbase, info.dli_sname, info.dli_saddr, (long)info.dli_saddr-(long)info.dli_fbase-0x1000, @""];
	NSLog(@"HTTPEEK DATA: %@\n", str);

	NSMutableData *dat = [NSMutableData dataWithData:[str dataUsingEncoding:NSUTF8StringEncoding]];
	[dat appendBytes:data length:dataLength];
	
	NSString *txt = [[NSString alloc] initWithBytesNoCopy:(void *)data length:dataLength encoding:NSUTF8StringEncoding freeWhenDone:YES];
	if (txt) NSLog(@"%@\n\n", txt);

	NSString *file = [NSString stringWithFormat:@"%@/DATA.%03d.%@", _logDir, s_index++, txt ? @"txt" : @"dat"];
	[dat writeToFile:file atomically:NO];
	
	return data;
}

//
#if __cplusplus
extern "C"
#endif
NSURLRequest *LogRequest(NSURLRequest *request, void *returnAddress)
{
	static int s_index = 0;
	static NSString *_logDir = nil;
	static std::vector<NSURLRequest *> _requests;

	if (_logDir == nil)
	{
		_logDir = [[NSString alloc] initWithFormat:@"/tmp/%@.req", NSProcessInfo.processInfo.processName];
		[[NSFileManager defaultManager] createDirectoryAtPath:_logDir withIntermediateDirectories:YES attributes:nil error:nil];
	}

	if ([request respondsToSelector:@selector(HTTPMethod)])
	{
		if (std::find(_requests.begin(), _requests.end(), request) == _requests.end())
		{
			_requests.push_back(request);
			if (_requests.size() > 1024)
			{
				_requests.erase(_requests.begin(), _requests.begin() + 512);
			}

			Dl_info info = {0};
			dladdr(returnAddress, &info);

			NSString *str = [NSString stringWithFormat:@"FROM %s(%p)-%s(%p=>%#08lx)\n<%@>\n%@: %@\n%@\n\n", info.dli_fname, info.dli_fbase, info.dli_sname, info.dli_saddr, (long)info.dli_saddr-(long)info.dli_fbase-0x1000, @"", request.HTTPMethod, request.URL.absoluteString, request.allHTTPHeaderFields ? request.allHTTPHeaderFields : @""];

			NSString *file = [NSString stringWithFormat:@"%@/%03d=%@.txt", _logDir, s_index++, NSUrlPath([request.URL.host stringByAppendingString:request.URL.path])];
			if (request.HTTPBody.length && request.HTTPBody.length < 10240)
			{
				NSString *str2 = [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding];
				if (str2)
				{
					//[[str stringByAppendingString:str2] writeToFile:file atomically:NO encoding:NSUTF8StringEncoding error:nil];
					
					NSLog(@"HTTPEEK REQUEST With Content: %@ \n%@\n\n", str, str2);
					return request;
				}
			}

			NSLog(@"HTTPEEK REQUEST: %@\n", str);
			[str writeToFile:file atomically:NO encoding:NSUTF8StringEncoding error:nil];
			[request.HTTPBody writeToFile:[file stringByAppendingString:@".dat"] atomically:NO];
		}
	}
	
	return request;
}

//
#if __cplusplus
extern "C"
#endif
int main()
{
#if DEBUG
	BOOL isDebug = YES;
#else
	BOOL isDebug = NO;
#endif
	_Log(@"Line Log: %s (%u) %s isDebug: %d", __FUNCTION__, __LINE__, __TIME__, isDebug);
	return 0;
}
